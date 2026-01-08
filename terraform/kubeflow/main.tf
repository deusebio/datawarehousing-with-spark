# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

module "kubeflow" {
  source = "git::https://github.com/canonical/charmed-kubeflow-solutions//modules/kubeflow?ref=wip-adding-proxy"
  create_model = false
  dex_static_username = "admin"
  dex_static_password = "admin"
  metacontroller_operator_revision = 551
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


