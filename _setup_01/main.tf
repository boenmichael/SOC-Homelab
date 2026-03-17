terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

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

# Create Network Interface for Splunk VM
resource "azurerm_network_interface" "splunk_nic" {
  name                = "splunk-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.soc_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.1.4"
  }
}

# Create Network Interface for AD VM
resource "azurerm_network_interface" "ad_nic" {
  name                = "ad-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ad_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.2.4"
  }
}

# Create Network Interface for Client VM
resource "azurerm_network_interface" "client_nic" {
  name                = "client-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.3.4"
  }
}

# Create Splunk SIEM VM
resource "azurerm_linux_virtual_machine" "splunk_vm" {
  name                = "vm-splunk"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.splunk_nic.id,
  ]

  admin_ssh_key {
    username   =  var.admin_username
    public_key = file(var.public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "kali-linux"
    offer     = "kali-linux"
    sku       = "kali-linux"
    version   = "latest"
  }
}

# Create AD VM
resource "azurerm_windows_virtual_machine" "ad_vm" {
  name                = "vm-ad"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.ad_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Create Client VM
resource "azurerm_windows_virtual_machine" "client_vm" {
  name                = "vm-client"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.client_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}