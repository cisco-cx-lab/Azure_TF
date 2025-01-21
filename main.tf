terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
 # skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
  subscription_id = var.subscription_id
  resource_provider_registrations = "none"
}

module "tvnet" {
  source              = "./modules/tvnet"
  resource_group_name = var.resource_group_name
  vnet_region         = var.vnet_region
  vnet_name           = var.transit_vnet_name
  address_space       = var.transit_vnet_address_space
}

module "vhub" {
  source                   = "./modules/vhub"
  vhub_name                = var.vhub_name
  vhub_location            = var.vhub_location
  vhub_resource_group_name = var.vhub_resource_group_name
  vnet_id                  = module.tvnet.vnet_id
  subnet_ids               = module.tvnet.subnet_ids
  subnet_service_ips       = module.tvnet.subnet_service_ips
  nva_bgp_asn              = var.nva_bgp_asn
  nva_ips                  = [
    module.tvnet.subnet_service_ips[0],
    module.tvnet.subnet_service_ips[1],
  ]
}
