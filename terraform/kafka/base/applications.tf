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

  storage     = [
    {
      count = 1
      label = "data"
      pool  = "kubernetes"
      size  = "10240M"
    },
  ]

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

  storage     = [
    {
      count = 1
      label = "zookeeper"
      pool  = "kubernetes"
      size  = "1024M"
    },
  ]

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
