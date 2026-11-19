# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

#############################
# Object Storage
#############################

module azure_storage {
  count = var.storage_backend == "azure_storage" ? 1 : 0
  source = "./azure"
  AZURE_REGION = var.azure_storage.region
  AZURE_RESOURCE_GROUP = var.azure_storage.resource_group
  AZURE_STORAGE_ACCOUNT = var.azure_storage.storage_account

  providers = {
    azurerm = azurerm
  }
}

#############################
# Observability Stack
#############################

resource "juju_model" "cos" {
  lifecycle {
    replace_triggered_by = []
  }

  name = "cos"

  credential = var.K8S_CREDENTIAL

  cloud {
    name = var.K8S_CLOUD
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
    juju-http-proxy = var.http_proxy
    juju-https-proxy = var.https_proxy
    juju-no-proxy = var.no_proxy
  }
}

module "cos" {
  depends_on = [juju_model.cos]
  source       = "git::https://github.com/canonical/observability-stack//terraform/cos-lite?ref=7448dadb996835c1c0ae1d79d2f435992652d410"
  model_uuid   = juju_model.cos.uuid
  internal_tls = false
}


#############################
# Spark
#############################

resource "juju_model" "spark" {
  lifecycle {
    replace_triggered_by = []
  }

  depends_on=[juju_model.kafka]

  name = "spark"

  credential = var.K8S_CREDENTIAL

  cloud {
    name = var.K8S_CLOUD
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
    juju-http-proxy = var.http_proxy
    juju-https-proxy = var.https_proxy
    juju-no-proxy = var.no_proxy

  }
}

module "spark" {
  depends_on = [module.cos, juju_model.spark]

  source                	  = "git::https://github.com/canonical/spark-k8s-bundle//terraform/products/charmed-spark?ref=336fad433d9bb2f1cae9c6cb0024c64ef19d911d"
  model_uuid                = juju_model.spark.uuid
  create_model              = false

  storage_backend           = var.storage_backend
  
  s3_access_key             = var.storage_backend == "s3" ? var.s3.access_key : null
  s3_secret_key             = var.storage_backend == "s3" ? var.s3.secret_key : null
  s3_config                 = var.storage_backend == "s3" ? {
    bucket               = var.s3.bucket
    endpoint             = var.s3.endpoint
    region               = var.s3.region
  } : {}
  
  
  azure_storage_secret_key      = var.storage_backend == "azure_storage" ? module.azure_storage[0].secret_key : null

  azure_storage_config          = var.storage_backend == "azure_storage" ? {
    container       = module.azure_storage[0].container_name
    storage_account = module.azure_storage[0].storage_account
    protocol        = "abfss"
  } : {}

  service_mesh_mode = "ambient"

  cos_offers = {
    dashboard=module.cos.offers.grafana_dashboards.url
    metrics=module.cos.offers.prometheus_receive_remote_write.url,
    logging=module.cos.offers.loki_logging.url
  }
}

#############################
# Kafka
#############################

resource "juju_model" "kafka" {
  lifecycle {
    replace_triggered_by = []
  }

  depends_on=[juju_model.cos]

  name = "kafka"

  credential = var.K8S_CREDENTIAL

  cloud {
    name = var.K8S_CLOUD
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
    # juju-http-proxy = var.http_proxy
    # juju-https-proxy = var.https_proxy
    # juju-no-proxy = var.no_proxy
  }
}

module "kafka" {
  depends_on = [module.cos, juju_model.kafka]

  source = "./kafka"

  model = juju_model.kafka.name
  cos = {
    deployed = "external"
    offers={
      dashboard=module.cos.offers.grafana_dashboards.url
      metrics=module.cos.offers.prometheus_receive_remote_write.url,
      logging=module.cos.offers.loki_logging.url
    }
  }
}

resource "juju_integration" "spark_streaming_hub" {

  depends_on = [module.spark,module.kafka]

  model      = "kafka"

  application {
    name = module.kafka.charms.spark_streaming
    endpoint = "spark-service-account"
  }

  application {
    offer_url = module.spark.offers.hub_service_account.url
  }

}

resource "juju_integration" "spark_streaming_metastore" {

  depends_on = [module.spark,module.kafka]

  model      = "kafka"

  application {
    name = module.kafka.charms.spark_streaming
    endpoint = "metastore"
  }

  application {
    offer_url = module.spark.offers.metastore_database.url
  }

}

#############################
# Kubeflow
#############################

resource "juju_model" "kubeflow" {
  count = var.enable_kubeflow ? 1 : 0

  lifecycle {
    replace_triggered_by = []
  }

  depends_on=[juju_model.spark]

  name = "kubeflow"

  credential = var.K8S_CREDENTIAL

  cloud {
    name = var.K8S_CLOUD
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
    juju-http-proxy = var.http_proxy
    juju-https-proxy = var.https_proxy
    juju-no-proxy = var.no_proxy
  }
}


module "kubeflow" {
  source                	  = "git::https://github.com/canonical/charmed-kubeflow-solutions//terraform/products/kubeflow?ref=1.11-ubuntu2"

  release            = 1.11
  risk               = stable
  create_model       = false
  model_uuid         = juju_model.kubeflow.uuid
  service_mesh_type  = ambient
  
  enable_kfp         = true
  enable_katib       = false
  enable_notebooks   = true
  enable_tensorboard = false
  enable_training_v1 = false
  enable_training_v2 = false
  enable_mlflow      = false
  enable_kserve      = false
  enable_feast       = false
  enable_spark       = false

  # Observability is always enabled in kubeflow-cos and automatically wired to COS
  enable_observability = true
  dashboards_offer     = module.cos.offers.grafana_dashboards.url
  logging_offer        = module.cos.offers.loki_logging.url
  metrics_offer        = module.cos.offers.prometheus_receive_remote_write.url

  external_integrations = {
    default = {
      profile = "*"
      mysql = null
      postgresql = null
      spark = {
        kind = "offer"
        url = module.spark.offers.integration_hub_service_account.url
        service_account = "spark-user"
      }
    }
  }
}

# resource "juju_integration" "kubeflow_integrator_integration_hub" {
#   count = var.enable_kubeflow ? 1 : 0
#   model = juju_model.kubeflow[0].name
# 
#   application {
#     name     = module.kubeflow[0].endpoints.kafka_client.app
#     endpoint = module.kubeflow[0].endpoints.kafka_client.endpoint
#   }
# 
#   application {
#     offer_url = module.kafka.offers.kafka_client.url
#   }
# }
# 