provider "azurerm" {
  features {}
}

resource "azurerm_management_group" "example" {
  name            = var.management_group_name
  display_name    = var.management_group_display_name
  parent_management_group_id       = var.parent_management_group_id
  subscription_ids = var.subscription_ids
}