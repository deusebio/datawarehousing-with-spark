# Copyright 2024 Canonical Ltd.
# See LICENSE file for licensing details.

output "container_name" {
  value = azurerm_storage_container.storagecontainer.name
}

output "storage_account" {
  value = azurerm_storage_account.storageaccount.name
}

output "secret_key" {
  value = azurerm_storage_account.storageaccount.primary_access_key
}
