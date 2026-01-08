# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "charms" {
  value = {
    kubeflow_integrator = juju_application.kubeflow_integrator.name
  }
}

output "endpoints" {
  value = {
    kafka_client = {
      app = juju_application.kubeflow_integrator.name
      endpoint = "kafka"
    }
    spark_client = {
      app = juju_application.kubeflow_integrator.name
      endpoint = "spark"
    }
  }
}