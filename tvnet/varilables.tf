variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "vnet_region" {
  description = "The Azure region"
  type        = string
}

variable "vnet_name" {
  description = "The name of the VNet"
  type        = string
}

variable "address_space" {
  description = "The address space of the VNet"
  type        = list(string)
}
