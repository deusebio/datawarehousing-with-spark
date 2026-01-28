# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "charms" {
  value = merge(
      module.base.charms, module.observability[*].charms...
  )
}

output "offers" {
  description = "The name and url of the various offers being exposed"
  value = merge(
    module.base.offers
  )
}
