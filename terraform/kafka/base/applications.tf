# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_application" "kafka" {
  name = "kafka"

  model      = var.model

  charm {
    name    = "kafka-k8s"
    channel = "3/edge"
    revision = 69
  }

  resources = {
    kafka-image = 46
  }

  storage_directives = {
    data = "kubernetes,1,10240M"
  }

  units = 1

  trust = true
  constraints = "arch=amd64"

}

resource "juju_application" "zookeeper" {
  name = "zookeeper"

  model      = var.model

  charm {
    name    = "zookeeper-k8s"
    channel = "3/edge"
    revision = 59
  }

  resources = {
    zookeeper-image = 31
  }

  storage_directives = {
    zookeeper = "kubernetes,1,10240M"
  }

  units = 1

  trust = true
  constraints = "arch=amd64"

}

resource "juju_application" "admin" {
  name = "admin"

  model      = var.model

  charm {
    name    = "data-integrator"
    channel = "latest/stable"
    revision = 41
  }

  units = 1

  config = {
    consumer-group-prefix = "admin-cg"
    extra-user-roles = "admin"
    topic-name = "test-topic"
  }

  constraints = "arch=amd64"
}

resource "juju_application" "producer" {
  name = "producer"

  model      = var.model

  charm {
    name    = "kafka-test-app"
    channel = "latest/edge"
    revision = 11
  }

  units = 1

  config = {
    num_messages = 80000
    role = "producer"
    topic_name = "test-topic"
  }

  constraints = "arch=amd64"
}

resource "juju_application" "spark_streaming" {
  name = "spark-streaming"

  model      = var.model

  charm {
    name    = "spark-test-app"
    channel = "latest/edge"
    revision = 1
  }

  resources = {
    spark-image = 1
  }

  units = 1

  config = {
    namespace = var.model
    flavour = "kafka"
    partitions = 10
    spark-image = "ghcr.io/canonical/charmed-spark@sha256:4c4e6f9d394348a26ec66969898434f007467b2caee03b2d393ddffd14dc2ecf"
  }

  constraints = "arch=amd64"
}
