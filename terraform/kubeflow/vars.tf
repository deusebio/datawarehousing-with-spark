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

variable "cos" {
  description = "Observability settings"
  type = object({
    model    = optional(string, "cos")
    deployed = optional(string, "bundled")
    offers = optional(object({
      dashboard = optional(string, null),
      metrics   = optional(string, null),
      logging   = optional(string, null)
    }), {}),
    tls = optional(object({
      cert = optional(string, "")
      key  = optional(string, "")
      ca   = optional(string, "")
    }), {})
  })
  default = { model = "cos", deployed = "bundled", offers = {}, tls = {} }

  validation {
    condition     = contains(["external", "bundled", "no"], var.cos.deployed)
    error_message = "Valid values for var: cos.deployed are (external, bundled, no)"
  }

  validation {
    condition = var.cos.deployed != "external" || alltrue([
      var.cos.offers.dashboard != null,
      var.cos.offers.metrics != null,
      var.cos.offers.logging != null,
    ])
    error_message = "When using external cos, please define all offers variables"
  }

}


