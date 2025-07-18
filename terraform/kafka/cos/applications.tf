# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_application" "agent" {
  name = "agent"

  model      = var.model

  charm {
    name    = "grafana-agent-k8s"
    channel = "1/stable"
    revision = 122
  }

  resources = {
      agent-image = 46
  }

  units = 1
  trust = true

  constraints = "arch=amd64"
}
