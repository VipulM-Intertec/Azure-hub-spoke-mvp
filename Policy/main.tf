provider "azurerm" {
  features {}
}

resource "azurerm_management_group_policy_assignment" "example" {
  name                 = var.policy_assignment_name
  display_name         = var.policy_assignment_display_name
  management_group_id  = var.policy_assignment_scope
  policy_definition_id = var.policy_definition_id
  parameters = var.policy_definition_perameter

}