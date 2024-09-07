# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

data "juju_offer" "grafana_dashboards" {
  url = local.endpoints.dashboards
}

data "juju_offer" "prometheus" {
  url = local.endpoints.prometheus
}

data "juju_offer" "loki" {
  url = local.endpoints.loki
}

# Relations between Apps <> Grafana Agent

# Kafka

resource "juju_integration" "kafka_agent_dashboards" {
  model      = var.model

  application {
    name = var.kafka
    endpoint = "grafana-dashboard"
  }

  application {
    name = juju_application.agent.name
    endpoint = "grafana-dashboards-consumer"
  }
}

resource "juju_integration" "kafka_agent_metrics" {
  model      = var.model

  application {
    name = var.kafka
    endpoint = "metrics-endpoint"
  }

  application {
    name = juju_application.agent.name
    endpoint = "metrics-endpoint"
  }
}


resource "juju_integration" "kafka_agent_logs" {
  model      = var.model

  application {
    name = var.kafka
    endpoint = "logging"
  }

  application {
    name = juju_application.agent.name
    endpoint = "logging-provider"
  }
}

# ZooKeeper

resource "juju_integration" "zookeeper_agent_dashboards" {
  model      = var.model

  application {
    name = var.zookeeper
    endpoint = "grafana-dashboard"
  }

  application {
    name = juju_application.agent.name
    endpoint = "grafana-dashboards-consumer"
  }
}

resource "juju_integration" "zookeeper_agent_metrics" {
  model      = var.model

  application {
    name = var.zookeeper
    endpoint = "metrics-endpoint"
  }

  application {
    name = juju_application.agent.name
    endpoint = "metrics-endpoint"
  }
}


resource "juju_integration" "zookeeper_agent_logs" {
  model      = var.model

  application {
    name = var.zookeeper
    endpoint = "logging"
  }

  application {
    name = juju_application.agent.name
    endpoint = "logging-provider"
  }
}

# Relations between COS <> Grafana Agent

resource "juju_integration" "agent_grafana_dashboards" {
  model      = var.model

  application {
    name = juju_application.agent.name
    endpoint = "grafana-dashboards-provider"
  }

  application {
    offer_url = data.juju_offer.grafana_dashboards.url
  }
}

resource "juju_integration" "agent_prometheus" {
  model      = var.model

  application {
    name = juju_application.agent.name
    endpoint = "send-remote-write"
  }

  application {
    offer_url = data.juju_offer.prometheus.url
  }
}

resource "juju_integration" "agent_loki" {
  model      = var.model

  application {
    name = juju_application.agent.name
    endpoint = "logging-consumer"
  }

  application {
    offer_url = data.juju_offer.loki.url
  }
}
