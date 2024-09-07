resource "juju_offer" "hub" {
  model            = var.model
  application_name = juju_application.hub.name
  endpoint         = spark-service-account
}

resource "juju_offer" "metastore" {
  model            = var.model
  application_name = juju_application.metastore.name
  endpoint         = database
}