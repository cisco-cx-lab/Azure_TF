resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.vnet_region
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
}

# subnets 
locals {
  # Assuming var.address_space[0] is a /24 network.
  # This will generate 8 /27 subnets, but we are using only the first 4.  
  subnet_cidr_blocks = cidrsubnets(var.address_space[0],3,3,3,3)
  subnet_names = ["public","private","service","mgmt"]
}

resource "azurerm_subnet" "subnet" {
  for_each = tomap({
    for i, name in local.subnet_names : name => local.subnet_cidr_blocks[i]
  })
  name                 = each.key
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value]
}

# Route Tables
resource "azurerm_route_table" "route_table" {
  for_each = toset(["public", "private"])
  name                = "${each.key}-route-table"
  location            = var.vnet_region
  resource_group_name = var.resource_group_name

  # disable gateway propagation on public rt
  bgp_route_propagation_enabled = each.key == "public" ? false : true
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "subnet_rt_association" {
  for_each = tomap({
    public  = azurerm_route_table.route_table["public"].id
    service = azurerm_route_table.route_table["private"].id
    mgmt    = azurerm_route_table.route_table["private"].id
    private = azurerm_route_table.route_table["private"].id
  })

  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = each.value
}

# Network Security Groups
resource "azurerm_network_security_group" "transport" {
  name                = "transport-nsg"
  location            = var.vnet_region
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
  #Change this prefix accordingly
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-UDP-12346-13156"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "12346-13156"
#Change this prefix accordingly
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "service" {
  name                = "service-nsg"
  location            = var.vnet_region
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-All-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
#Change this prefix accordingly
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs to Subnets
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each = tomap({
    public  = azurerm_network_security_group.transport.id
    private = azurerm_network_security_group.service.id
    service = azurerm_network_security_group.service.id
    mgmt    = azurerm_network_security_group.transport.id
  })

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value
}

# Network Interfaces (2 per subnet)
resource "azurerm_network_interface" "nic" {
  for_each = tomap({
    for subnet_name, subnet in azurerm_subnet.subnet : "${subnet_name}-nic-1" => subnet if subnet_name != "public"
  })

  name                = each.key
  location            = var.vnet_region
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = each.value.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(each.value.address_prefixes[0], 5) # Subnet + 5
  }
  ip_forwarding_enabled = true
}

# Second NIC per subnet
resource "azurerm_network_interface" "nic_second" {
  for_each = tomap({
    for subnet_name, subnet in azurerm_subnet.subnet : "${subnet_name}-nic-2" => subnet if subnet_name != "public"
  })

  name                = each.key
  location            = var.vnet_region
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = each.value.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(each.value.address_prefixes[0], 6) # Subnet + 6
  }
  ip_forwarding_enabled = true
}

# Public IPs for NICs in the Public Subnet
resource "azurerm_public_ip" "public_ip" {
  for_each = tomap({
    "public-nic-1" = "public-nic-1-pip"
    "public-nic-2" = "public-nic-2-pip"
  })

  name                = each.value
  location            = var.vnet_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

# Update NICs in Public Subnet with Public IPs
resource "azurerm_network_interface" "public_nic" {
  for_each = tomap({
    "public-nic-1" = {
      subnet  = azurerm_subnet.subnet["public"]
      ip_addr = cidrhost(azurerm_subnet.subnet["public"].address_prefixes[0], 5)
    }
    "public-nic-2" = {
      subnet  = azurerm_subnet.subnet["public"]
      ip_addr = cidrhost(azurerm_subnet.subnet["public"].address_prefixes[0], 6)
    }
  })

  name                = each.key
  location            = var.vnet_region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = each.value.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_addr
    public_ip_address_id          = azurerm_public_ip.public_ip[each.key].id
  }

  ip_forwarding_enabled = true
}

# Declare the azurerm_network_interface_security_group_association resource
resource "azurerm_network_interface_security_group_association" "nic" {
  for_each = tomap({
    "public-nic-1"  = azurerm_network_interface.public_nic["public-nic-1"].id
    "private-nic-1" = azurerm_network_interface.nic["private-nic-1"].id
    "service-nic-1" = azurerm_network_interface.nic["service-nic-1"].id
    "mgmt-nic-1"    = azurerm_network_interface.nic["mgmt-nic-1"].id
    "public-nic-2"  = azurerm_network_interface.public_nic["public-nic-2"].id
    "private-nic-2" = azurerm_network_interface.nic_second["private-nic-2"].id
    "service-nic-2" = azurerm_network_interface.nic_second["service-nic-2"].id
    "mgmt-nic-2"    = azurerm_network_interface.nic_second["mgmt-nic-2"].id
  })
    network_interface_id = each.value
  network_security_group_id = azurerm_network_security_group.transport.id
}
# Provision 2 VMs # Provision 2 VMs
resource "azurerm_virtual_machine" "vm" {
  for_each = tomap({
    c8kv-1 = {
      public_nic  = azurerm_network_interface.public_nic["public-nic-1"].id
      private_nic = azurerm_network_interface.nic["private-nic-1"].id
      service_nic = azurerm_network_interface.nic["service-nic-1"].id
      mgmt_nic    = azurerm_network_interface.nic["mgmt-nic-1"].id
      init_file   = "bootstrap/cat8000v-c8kv-1-cloud.init.txt"
    }
    c8kv-2 = {
      public_nic  = azurerm_network_interface.public_nic["public-nic-2"].id
      private_nic = azurerm_network_interface.nic_second["private-nic-2"].id
      service_nic = azurerm_network_interface.nic_second["service-nic-2"].id
      mgmt_nic    = azurerm_network_interface.nic_second["mgmt-nic-2"].id
      init_file   = "bootstrap/cat8000v-c8kv-2-cloud.init.txt"
    }
  })

  name                  = each.key
  location              = var.vnet_region
  resource_group_name   = var.resource_group_name
  vm_size               = "Standard_D8s_v3"  # Use vm_size from the reference
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  # accept_marketplace_agreement = true
  # enable diagnostics to allow console from azure portal
  #boot_diagnostics  {
  #  enabled = true
  # storage_uri = "https://<your-storage-account-name>.blob.core.windows.net/"
  #}
  # run command az vm image accept-terms --urn cisco:cisco-c8000v-byol:17_12_04-byol:latest to accept term
  plan {
    publisher = "cisco"
    product   = "cisco-c8000v-byol"
    name      = "17_12_04-byol"
  }
  primary_network_interface_id = each.value.public_nic
  storage_os_disk {
    name              = "${each.key}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-c8000v-byol"
    sku       = "17_12_04-byol"
  ## Find cisco images az vm image list -o table --publisher cisco --offer cisco-c8000v-byol --all  
    version   = "latest"
  }

  network_interface_ids = [
    each.value.public_nic,
    each.value.private_nic,
    each.value.service_nic,
    each.value.mgmt_nic,
  ]

  os_profile {
    computer_name  = each.key
    admin_username = "azureuser"
    admin_password = "Password123!"
    custom_data    = file(each.value.init_file)
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  # tags = var.common_tags

  depends_on = [
    azurerm_network_interface_security_group_association.nic
  ]
}

