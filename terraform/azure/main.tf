resource "azurerm_resource_group" "rg" {
  name     = var.AZURE_RESOURCE_GROUP
  location = var.AZURE_REGION
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = var.AZURE_STORAGE_ACCOUNT
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = "true"
}


resource "azurerm_storage_container" "storagecontainer" {
  name                  = "sparktestcontainer"
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "private"
}


resource "azurerm_storage_blob" "spark-folder" {
  name                   = "spark-events/example.txt"
  storage_account_name   = azurerm_storage_account.storageaccount.name
  storage_container_name = azurerm_storage_container.storagecontainer.name
  type                   = "Block"
  source                 = "./example.txt"
}
