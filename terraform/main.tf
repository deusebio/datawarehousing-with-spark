# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_model" "spark" {
  lifecycle {
    replace_triggered_by = []
  }

  name = "spark"

  cloud {
    name = "microk8s"
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
  }
}

resource "juju_model" "kafka" {
  lifecycle {
    replace_triggered_by = []
  }

  name = "kafka"

  cloud {
    name = "microk8s"
  }

  config = {
    logging-config              = "<root>=INFO"
    update-status-hook-interval = "5m"
  }
}

module "spark" {
  source = "./spark"

  depends_on = [juju_model.spark]

  model = juju_model.spark.name
  s3 = var.s3
  cos_model = var.cos_model
}

module "kafka" {
  source = "./kafka"

  depends_on = [juju_model.kafka]

  model = juju_model.kafka.name
  cos_model = var.cos_model
}

resource "juju_integration" "spark_streaming_hub" {

  depends_on = [module.spark,module.kafka]

  model      = "kafka"

  application {
    name = module.kafka.charms.spark_streaming
    endpoint = "spark-service-account"
  }

  application {
    offer_url = module.spark.offers.hub_service_account
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
    offer_url = module.spark.offers.metastore_database
  }

}