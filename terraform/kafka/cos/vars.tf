# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

variable "model" {
  description = "The name of the Juju Model to deploy to"
  type        = string
  default     = "spark"
}

variable "kafka" {
  description = "Name of the kafka charm deployment"
  type        = string
  default     = "kafka"
}

variable "zookeeper" {
  description = "Name of the zookeeper charm deployment"
  type        = string
  default     = "zookeeper"
}

# cos specifics

variable "dashboards_offer" {
  description = "URL of the `grafana_dashboard` interface offer."
  type        = string
  nullable    = false
}

variable "metrics_offer" {
  description = "URL of the `prometheus_remote_write` interface offer."
  type        = string
  nullable    = false
}

variable "logging_offer" {
  description = "URL of the `loki_push_api` interface offer."
  type        = string
  nullable    = false
}
