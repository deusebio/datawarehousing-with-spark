# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

# ====================
# PATTERN TO BE TESTED
# ====================
# resource "juju_model" "spark" {
#   lifecycle {
#     replace_triggered_by = []
#   }
#
#   name = var.model
#
#   cloud {
#     name = "microk8s"
#   }
#
#   config = {
#     logging-config              = "<root>=DEBUG"
#     update-status-hook-interval = "5m"
#   }
# }

data "juju_model" "spark" {
  name = var.model
}

module "base" {
  source = "./base"

  model = data.juju_model.spark.name
}

module "cos" {
  count  = var.cos_model == null ? 0 : 1
  source = "./cos"

  model = data.juju_model.spark.name
  kafka = module.base.charms.kafka
  zookeeper = module.base.charms.zookeeper
  cos_model = var.cos_model
}