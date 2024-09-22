# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

variable "s3" {
  description = "S3 Bucket information"
  type = object({
    bucket               = optional(string, "spark-test")
    endpoint             = optional(string, "https://s3.amazonaws.com")
  })
  default = {}
}

variable "cos_model" {
  description = "The name of the model where cos is deployed. If null, don't deploy cos related charms."
  type = string
  nullable = true
  default = null
}
