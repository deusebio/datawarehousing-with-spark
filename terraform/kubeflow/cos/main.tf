## COS <> KUBEFLOW INTEGRATIONS

data "juju_offer" "grafana_dashboards" {
  url = var.dashboards_offer
}

data "juju_offer" "prometheus" {
  url = var.metrics_offer
}

data "juju_offer" "loki" {
  url = var.logging_offer
}


resource "juju_integration" "agent_grafana_dashboards" {
  model =  var.model

  application {
    name     = var.opentelemetry_collector_name
    endpoint = "grafana-dashboards-provider"
  }

  application {
    offer_url = data.juju_offer.grafana_dashboards.url
  }

}

resource "juju_integration" "agent_prometheus" {
  model = var.model

  application {
    name     = var.opentelemetry_collector_name
    endpoint = "send-remote-write"
  }

  application {
    offer_url =  data.juju_offer.prometheus.url
  }

}

resource "juju_integration" "agent_loki" {
  model = var.model

  application {
    name     = var.opentelemetry_collector_name
    endpoint = "send-loki-logs"
  }

  application {
    offer_url = data.juju_offer.loki.url
  }

}

