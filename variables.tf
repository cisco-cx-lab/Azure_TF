variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID"
  type = string
}
variable "vnet_region" {
  description = "The Azure region"
  type        = string
}

variable "transit_vnet_name" {
  description = "The name of the transit VNet"
  type        = string
}

variable "transit_vnet_address_space" {
  description = "The address space of the transit VNet"
  type        = list(string)
}

variable "vhub_name" {
  description = "Name of the virtual hub."
  type        = string
}

variable "vhub_location" {
  description = "Location of the virtual hub."
  type        = string
}

variable "vhub_resource_group_name" {
  description = "Resource group name for the virtual hub."
  type        = string
}

variable "nva_bgp_asn" {
  description = "ASN for the NVA BGP."
  type        = number
}


#variable "subnet_names" {
#  description = "The names of the subnets"
#  type        = list(string)
#}

#variable "subnet_prefixes" {
#  description = "The address prefixes for the subnets"
#  type        = list(string)
#}
#variable "admin_username" {
#  description = "username for vm"
#  type        = string
#}
#variable "admin_password" {
#  description = "admin password for vm"
#  type        = string
#}