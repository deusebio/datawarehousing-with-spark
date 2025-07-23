variable "AZURE_RESOURCE_GROUP" {
  type = string
  description = "Name of the resource group to be created for the Azure Blob storage"
  default = "TestSparkAKS"
}

variable "AZURE_REGION" {
  type = string
  description = "Location to be used for Azure Blob Storage deployment"
  default = "East US"
}

variable "AZURE_STORAGE_ACCOUNT" {
  type = string
  description = "Name for the storage account to be used for the Azure Blob Storage"
  default = "sparktestaks"
}