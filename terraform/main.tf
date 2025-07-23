# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

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
  }
}

module "cos" {
  depends_on = [juju_model.cos]
  source     = "git::https://github.com/canonical/observability-stack//terraform/cos-lite"
  model = juju_model.cos.name
  channel = "1/stable"
  internal_tls = false
}

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
  }
}

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


module "spark" {
  source                	= "git::https://github.com/canonical/spark-k8s-bundle//releases/3.4/terraform?ref=dpe-7677-demo-updates"
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
  integration_hub_revision  = 65
  history_server_revision   = 45

  cos                       = {
    deployed = "external"
    offers={
      dashboard=module.cos.offers.grafana_dashboards.url
      metrics=module.cos.offers.prometheus_receive_remote_write.url,
      logging=module.cos.offers.loki_logging.url
    }
  }
}


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
  }
}


module "kafka" {
  source = "./kafka"

  depends_on = [juju_model.kafka]

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