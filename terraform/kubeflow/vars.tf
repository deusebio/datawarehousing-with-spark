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

