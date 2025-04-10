terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.24.0"
    }

  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "4ec07199-c6ff-45c2-8d71-ee21069f4b7d"
}


