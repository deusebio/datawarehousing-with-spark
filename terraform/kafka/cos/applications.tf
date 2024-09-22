# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_application" "agent" {
  name = "agent"

  model      = var.model

  charm {
    name    = "grafana-agent-k8s"
    channel = "latest/stable"
    revision = 64
  }

  resources = {
      agent-image = 38
  }

  units = 1
  trust = true

  constraints = "arch=amd64"
}
