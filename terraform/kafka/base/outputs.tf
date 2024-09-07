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
