# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

terraform {
  required_version = ">=1.7.3"

  required_providers {
    juju = {
      version = ">= 0.20.0"
      source  = "juju/juju"
    }
  }
}

provider "juju" {
  controller_addresses = var.JUJU_CONTROLLER_IPS
  username         	= var.JUJU_USERNAME
  password         	= var.JUJU_PASSWORD
  ca_certificate   	= base64decode(var.JUJU_CA_CERTIFICATE)
}
