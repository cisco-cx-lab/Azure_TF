
resource "azurerm_virtual_hub_connection" "vnet_to_vhub" {
  name                     = "vnet-to-${var.vhub_name}-connection"
  virtual_hub_id           = data.azurerm_virtual_hub.vhub.id
  remote_virtual_network_id = var.vnet_id
  # enable_internet_security = false
  # tags                     = var.tags
}

resource "azurerm_virtual_hub_bgp_connection" "bgp_connection" {
  depends_on = [azurerm_virtual_hub_connection.vnet_to_vhub]
  for_each = toset(var.nva_ips)

  name                   = "bgp-${each.value}"
  virtual_hub_id         = data.azurerm_virtual_hub.vhub.id
  peer_asn               = var.nva_bgp_asn
  peer_ip                = each.value
  virtual_network_connection_id = azurerm_virtual_hub_connection.vnet_to_vhub.id
  # enable_bfd             = true
  # enable_route_filtering = false
  # tags                   = var.tags
}

data "azurerm_virtual_hub" "vhub" {
  name                = var.vhub_name
  resource_group_name = var.vhub_resource_group_name
}