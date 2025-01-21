output "vhub_id" {
  value = data.azurerm_virtual_hub.vhub.id
}

output "vhub_name" {
  value = data.azurerm_virtual_hub.vhub.name
}

output "vhub_connection_id" {
  value = azurerm_virtual_hub_connection.vnet_to_vhub.id
}

output "bgp_peering_status" {
  value = {
    for bgp_peer, config in azurerm_virtual_hub_bgp_connection.bgp_connection :
    bgp_peer => config.peer_ip
  }
}
