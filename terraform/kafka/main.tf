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

data "juju_model" "kafka" {
  name = var.model
}

data "juju_model" "cos" {
  name = var.cos.model
}


module "base" {
  source = "./base"

  model = data.juju_model.kafka.name
}

module "bundled_cos" {
  count        = var.cos.deployed == "bundled" ? 1 : 0
  source       = "git::https://github.com/canonical/spark-k8s-bundle//releases/3.4/terraform/external/cos?ref=rev2"
  model        = data.juju_model.cos.name
  cos_tls_ca   = var.cos.tls.ca
  cos_tls_cert = var.cos.tls.cert
  cos_tls_key  = var.cos.tls.key
}

module "observability" {
  depends_on       = [module.base, module.bundled_cos]
  count            = var.cos.deployed == "no" ? 0 : 1
  source           = "./cos"
  dashboards_offer = var.cos.deployed == "external" ? var.cos.offers.dashboard : one(module.bundled_cos[*].dashboards_offer)
  logging_offer    = var.cos.deployed == "external" ? var.cos.offers.logging : one(module.bundled_cos[*].logging_offer)
  metrics_offer    = var.cos.deployed == "external" ? var.cos.offers.metrics : one(module.bundled_cos[*].metrics_offer)

  model = data.juju_model.kafka.name
  kafka = module.base.charms.kafka
  zookeeper = module.base.charms.zookeeper
}
