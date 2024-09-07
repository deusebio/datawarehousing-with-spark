# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_integration" "kafka_zookeeper" {
  model      = var.model

  application {
    name = juju_application.kafka.name
    endpoint = "zookeeper"
  }

  application {
    name = juju_application.zookeeper.name
    endpoint = "zookeeper"
  }
}

resource "juju_integration" "kafka_admin" {
  model      = var.model

  application {
    name = juju_application.admin.name
    endpoint = "kafka"
  }

  application {
    name = juju_application.kafka.name
    endpoint = "kafka-client"
  }
}
