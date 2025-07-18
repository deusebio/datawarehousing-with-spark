# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

variable "JUJU_CONTROLLER_IPS" {
  type        = string
  description = "Juju controller IP addresses, comma separated"
}

variable "JUJU_USERNAME" {
  type        = string
  description = "Username for the juju controller"
}

variable "JUJU_PASSWORD" {
  type        = string
  description = "Password for the juju controller"
}

variable "JUJU_CA_CERTIFICATE" {
  type        = string
  description = "Juju controller CA certificate"
}

variable "K8S_CLOUD" {
  type        = string
  description = "The kubernetes juju cloud name."
}

variable "K8S_CREDENTIAL" {
  type        = string
  description = "The name of the kubernetes juju credential."
}



variable "s3" {
  description = "S3 Bucket information"
  type = object({
    bucket               = optional(string, "spark-test")
    endpoint             = optional(string, "https://s3.amazonaws.com")
  })
  default = {}
}
