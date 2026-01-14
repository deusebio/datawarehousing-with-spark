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
  source     = "git::https://github.com/canonical/observability-stack//terraform/cos-lite?ref=tf-provider-v0"
  model = juju_model.cos.name
  channel = "1/stable"
  internal_tls = false
}

#############################
# Spark
#############################

resource "juju_model" "spark" {
  lifecycle {
    replace_triggered_by = []
  }

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

  source                	= "git::https://github.com/canonical/spark-k8s-bundle//releases/3.4/terraform?ref=0f35e48125b680ae827e6efa2a1a481513d01243"
  model                 	= juju_model.spark.name
  create_model              = false
  K8S_CLOUD                 = var.K8S_CLOUD
  K8S_CREDENTIAL            = var.K8S_CREDENTIAL
  storage_backend           = var.storage_backend
  s3                        = var.storage_backend == "s3" ? var.s3 : {}
  azure_storage             = var.storage_backend == "azure_storage" ? {
    container       = module.azure_storage[0].container_name
    storage_account = module.azure_storage[0].storage_account
    secret_key      = module.azure_storage[0].secret_key
    protocol        = "abfss"
  } : {}
  zookeeper_units           = 1
  kyuubi_units              = 1

  integration_hub_revision  = 90
  integration_hub_image     = {
    integration-hub-image = "ghcr.io/canonical/spark-integration-hub@sha256:dbcd4bce247df35483bb94606fa11d3316d9d529e1476efa95ef333b78c9f414"
  }
  
  cos                       = {
    deployed = "external"
    offers={
      dashboard=module.cos.offers.grafana_dashboards.url
      metrics=module.cos.offers.prometheus_receive_remote_write.url,
      logging=module.cos.offers.loki_logging.url
    }
  }
}

#############################
# Kafka
#############################

resource "juju_model" "kafka" {
  lifecycle {
    replace_triggered_by = []
  }

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
  depends_on = [module.cos, juju_model.kubeflow]

  count = var.enable_kubeflow ? 1 : 0

  source = "./kubeflow"
  profile = "*"
  topic_name = "test-topic"

  cos                       = {
    deployed = "external"
    offers={
      dashboard=module.cos.offers.grafana_dashboards.url
      metrics=module.cos.offers.prometheus_receive_remote_write.url,
      logging=module.cos.offers.loki_logging.url
    }
  }

}

resource "juju_integration" "kubeflow_integrator_kafka_client" {
  count = var.enable_kubeflow ? 1 : 0
  model = juju_model.kubeflow[0].name

  application {
    name     = module.kubeflow[0].endpoints.spark_client.app
    endpoint = module.kubeflow[0].endpoints.spark_client.endpoint
  }

  application {
    offer_url = module.spark.offers.hub_service_account.url
  }
}

resource "juju_integration" "kubeflow_integrator_integration_hub" {
  count = var.enable_kubeflow ? 1 : 0
  model = juju_model.kubeflow[0].name

  application {
    name     = module.kubeflow[0].endpoints.kafka_client.app
    endpoint = module.kubeflow[0].endpoints.kafka_client.endpoint
  }

  application {
    offer_url = module.kafka.offers.kafka_client.url
  }
}
