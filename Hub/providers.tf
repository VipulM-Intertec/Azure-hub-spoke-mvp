/**

terraform {
  backend "azurerm" {}
}

**/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.62.1"
    }
  }

  required_version = ">= 1.3.9"
}
provider "azurerm" {
  skip_provider_registration = true
/*
    tenant_id       = "xxxxx"
    subscription_id = "xxxxx"
    client_id       = "xxxxx"
    client_secret   = "xxxxx"
*/
  features {
        key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
