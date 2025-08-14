# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

variable "model" {
  description = "The name of the Juju Model to deploy to"
  type        = string
  default     = "kafka"
}

# cos specifics

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
