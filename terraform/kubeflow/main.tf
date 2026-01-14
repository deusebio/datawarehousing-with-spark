# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

module "kubeflow" {
  # source = "git::https://github.com/canonical/charmed-kubeflow-solutions//modules/kubeflow?ref=wip-adding-proxy"
  source = "git::https://github.com/canonical/charmed-kubeflow-solutions//modules/kubeflow?ref=kf-8292-replace-grafana-agent-k8s"
  create_model = false
  dex_static_username = "admin"
  dex_static_password = "admin"
  metacontroller_operator_revision = 551
  cos_configuration = var.cos.deployed == "no" ? false : true
}

module "resource_dispatcher" {
  source     = "git::https://github.com/canonical/resource-dispatcher//terraform?ref=893c73d48f49023f0cf3aa13927a609167d53bf7"
  model_name = "kubeflow"
  revision   = 410
  channel    = "2.0/stable"
}

resource "juju_application" "kubeflow_integrator" {
 model  = module.kubeflow.model
  name  = "kubeflow-integrator"
  charm {
    name     = "data-kubeflow-integrator"
    channel  = "1/edge" # TODO: fix hardcoded value
  }
  units       = 1
  constraints = "arch=amd64"
  trust       = true
  config = {
    spark-service-account = var.spark_user
    profile = var.profile
    kafka-topic-name = var.topic_name
    kafka-consumer-group-prefix = var.consumer_group
    kafka-extra-user-roles = "admin"
  }
}

resource "juju_integration" "kubeflow_integrator_resource_dispatcher_secrets" {
  model = module.kubeflow.model

  application {
    name     = juju_application.kubeflow_integrator.name
    endpoint = "secrets"
  }

  application {
    name     = module.resource_dispatcher.app_name
    endpoint = module.resource_dispatcher.provides.secrets
  }
}

resource "juju_integration" "kubeflow_integrator_resource_dispatcher_service_accounts" {
  model = module.kubeflow.model

  application {
    name     = juju_application.kubeflow_integrator.name
    endpoint = "service-accounts"
  }

  application {
    name     = module.resource_dispatcher.app_name
    endpoint = module.resource_dispatcher.provides.service_accounts
  }
}

resource "juju_integration" "kubeflow_integrator_resource_dispatcher_poddefaults" {
  model = module.kubeflow.model

  application {
    name     = juju_application.kubeflow_integrator.name
    endpoint = "pod-defaults"
  }

  application {
    name     = module.resource_dispatcher.app_name
    endpoint = module.resource_dispatcher.provides.pod_defaults
  }
}

resource "juju_integration" "kubeflow_integrator_resource_dispatcher_roles" {
  model = module.kubeflow.model

  application {
    name     = juju_application.kubeflow_integrator.name
    endpoint = "roles"
  }

  application {
    name     = module.resource_dispatcher.app_name
    endpoint = module.resource_dispatcher.provides.roles
  }
}

resource "juju_integration" "kubeflow_integrator_resource_dispatcher_rolebindings" {
  model = module.kubeflow.model

  application {
    name     = juju_application.kubeflow_integrator.name
    endpoint = "role-bindings"
  }

  application {
    name     = module.resource_dispatcher.app_name
    endpoint = module.resource_dispatcher.provides.role_bindings
  }
}

data "juju_model" "cos" {
  name = var.cos.model
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
  depends_on       = [module.kubeflow, module.bundled_cos]
  count            = var.cos.deployed == "no" ? 0 : 1
  source           = "./cos"
  dashboards_offer = var.cos.deployed == "external" ? var.cos.offers.dashboard : one(module.bundled_cos[*].dashboards_offer)
  logging_offer    = var.cos.deployed == "external" ? var.cos.offers.logging : one(module.bundled_cos[*].logging_offer)
  metrics_offer    = var.cos.deployed == "external" ? var.cos.offers.metrics : one(module.bundled_cos[*].metrics_offer)

  model = module.kubeflow.model
  opentelemetry_collector_name = module.kubeflow.opentelemetry_collector_k8s.app_name
}
