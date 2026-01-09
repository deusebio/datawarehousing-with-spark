# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

variable "profile" {
  description = "The name of the Juju Model where spark is deployed"
  type        = string
  default     = "admin"
}

variable "spark_user" {
  description = "The name of the Juju Model where spark is deployed"
  type        = string
  default     = "spark-user"
}

variable "topic_name" {
  description = "The name of the Juju Model where spark is deployed"
  type        = string
  default     = "test-topic"
}

variable "consumer_group" {
  description = "The name of the Juju Model where spark is deployed"
  type        = string
  default     = "kfgc"
}

