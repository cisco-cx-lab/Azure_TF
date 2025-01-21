# Azure Network Architecture
This Terraform configuration automates the deployment of a multi-subnet Azure Virtual Network (VNet) with network security, BGP connections to a Virtual Hub, and VM provisioning.

## Overview
This setup deploys the following components:

* A Transit VNet with multiple subnets (public, private, service, mgmt)
* Virtual Hub with BGP connection configuration
* Virtual Machines connected to each subnet via multiple NICs (Private, Service, Management, and Public)
* Network Security Groups (NSGs) for securing traffic between different subnets

### High-Level Architecture

```plaintext
+--------------------------------------+
|         Azure Virtual Hub            |
|   +------------------------------+   |
|   | BGP Connection (NVA)         |   |
|   +------------------------------+   |
|                  |                   |
|        +----------------+             |
|        | VNet-to-VHub   |             |
|        +----------------+             |
|              |                      |
|     +----------------+               |
|     | Transit VNet    |               |
|     +----------------+               |
|         |   |   |   |                |
|    +---+---+---+---+---+             |
|    | Subnets: Public, Private,       |
|    | Service, Mgmt                   |
|    +-------------------------------+ |
|        |    |    |    |              |
|   +----+----+----+----+-----+        |
|   | VMs (C8KV-1, C8KV-2)              |
|   +----------------------------------+ |
+--------------------------------------+
```
## Terraform Modules

### Root Module

- **Configuration**: Configures the `azurerm` provider and sets up the Virtual Network (`tvnet`) and Virtual Hub (`vhub`) modules.
- **Modules Used**:
  - `tvnet`: Manages the transit VNet and its subnets.
  - `vhub`: Configures a Virtual Hub, BGP connections, and links it to the Transit VNet.

### `tvnet` Module

- Creates a virtual network (`azurerm_virtual_network`) and subnets (`azurerm_subnet`).
- Configures network security groups (NSGs) and route tables to manage routing and traffic control between the subnets.

### `vhub` Module

- Configures a Virtual Hub (`azurerm_virtual_hub`) and a BGP connection (`azurerm_virtual_hub_bgp_connection`).
- Establishes the connection between the Transit VNet and the Virtual Hub.

### BGP Configuration

The **BGP Connection** connects a Virtual Hub to a Virtual Network with route propagation. It uses the `azurerm_virtual_hub_connection` and `azurerm_virtual_hub_bgp_connection` resources to establish communication between the VNet and NVA.

## Variables 
The following variables need to be defined: 
variable "subscription_id" {}
variable "resource_group_name" {}
variable "vnet_region" {}
variable "transit_vnet_name" {}
variable "transit_vnet_address_space" {}
variable "vhub_name" {}
variable "vhub_location" {}
variable "nva_ips" {}
variable "nva_bgp_asn" {}

### Use 'values.tfvars'
Before applying the Terraform configuration, create a `values.tfvars` file to specify the required variables.

```hcl
resource_group_name         = "your-resource-group-name"  # Example: CX_SDWAN
subscription_id             = "your-subscription-id"      # Example: 561a057e-####-####-abd7-####
vnet_region                 = "your-region"               # Example: eastus
transit_vnet_name           = "your-vnet-name"            # Example: use-wan-tvnet
transit_vnet_address_space  = ["your-address-space"]      # Example: ["192.168.11.0/24"]
nva_bgp_asn                 = "your-bgp-asn"              # Example: 65002
vhub_location              = "your-hub-location"        # Example: eastus
vhub_name                   = "your-hub-name"            # Example: east_hub
vhub_resource_group_name    = "your-hub-resource-group"   # Example: CX_SDWAN

Replace the example values with your own Azure configuration details.
```
## How to Deploy
1. Clone this repository to your local machine
2. Initialize the Terraform workspace
3. Apply the Terraform plan

