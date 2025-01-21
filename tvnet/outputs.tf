output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  description = "The location of the Virtual Network"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_resource_group_name" {
  description = "The resource group name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.resource_group_name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for subnet_name, subnet in azurerm_subnet.subnet :
    subnet_name => subnet.id
  }
}

output "subnet_service_ips" {
  description = "List of private IPs from the network interfaces in the 'service' subnet"
  value = flatten(concat(
    [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address if nic.name == "service-nic-1"],
    [for nic in azurerm_network_interface.nic_second : nic.ip_configuration[0].private_ip_address if nic.name == "service-nic-2"]
  ))
}

