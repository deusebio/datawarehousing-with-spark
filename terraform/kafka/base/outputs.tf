# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "charms" {
  value = {
    kafka = juju_application.kafka.name
    zookeeper = juju_application.zookeeper.name
    admin = juju_application.admin.name
    producer = juju_application.producer.name
  }
}

output "cos_endpoint" {
  value = {
    charm = juju_application.hub.name
    endpoint = "cos"
  }
}

output "history_server_ingress" {
  value = {
    charm = juju_application.history_server.name
    endpoint = "ingress"
  }
}