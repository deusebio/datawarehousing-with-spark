# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "charms" {
  value = {
    history_server = juju_application.history_server.name
    s3 = juju_application.s3.name
    kyuubi = juju_application.kyuubi.name
    metastore = juju_application.metastore.name
    hub = juju_application.hub.name
  }
}

output "offers" {
  value = {
    hub_service_account = juju_offer.hub.url
    metastore_database = juju_offer.metastore.url
  }
}