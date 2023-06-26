variable "management_group_name" {
  description = "The name of the management group"
  type        = string
}

variable "management_group_display_name" {
  description = "The display name of the management group"
  type        = string
}

variable "parent_management_group_id" {
  description = "The ID of the parent management group or the root management group"
  type        = string
}

variable "subscription_ids" {
  description = "A list of subscription IDs associated with the management group"
  type        = list(string)
}
