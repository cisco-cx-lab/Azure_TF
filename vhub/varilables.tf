variable "vhub_name" {
  description = "Name of the Virtual Hub."
  type        = string
}

variable "vhub_location" {
  description = "Location of the Virtual Hub."
  type        = string
}

variable "vhub_resource_group_name" {
  description = "Resource group name where the Virtual Hub is located."
  type        = string
}

variable "vnet_id" {
  description = "ID of the Virtual Network to connect to the Virtual Hub."
  type        = string
}


variable "subnet_ids" {
  description = "Map of subnet IDs within the Virtual Network."
  type        = map(string)
}

variable "subnet_service_ips" {
  description = "List of service subnet IPs for NVAs to establish BGP peering."
  type        = list(string)
}

variable "nva_bgp_asn" {
  description = "BGP ASN of the NVAs for peering."
  type        = number
}

variable "tags" {
  description = "Optional tags to assign to resources."
  type        = map(string)
  default     = {}
}
variable "nva_ips" {
  description = "List of NVA IPs for routing and peering configuration."
  type        = list(string)
}
