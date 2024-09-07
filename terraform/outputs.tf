# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "charms" {
  value = merge(
      module.kafka.charms, module.spark.charms
  )
}

