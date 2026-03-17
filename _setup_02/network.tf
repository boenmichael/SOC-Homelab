# Create Resource Group
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

# Create Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = "SOC-VNET"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
}

# Create Subnets (soc_subnet, ad_subnet, client_subnet)
resource "azurerm_subnet" "soc_subnet" {
  name                 = "soc-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.soc_subnet_cidr]
}

resource "azurerm_subnet" "ad_subnet" {
  name                 = "ad-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.ad_subnet_cidr]
}

resource "azurerm_subnet" "client_subnet" {
  name                 = "client-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.client_subnet_cidr]
}
