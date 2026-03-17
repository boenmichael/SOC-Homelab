# Bastion subnet required by Azure Bastion
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "soc-bastion-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "this" {
  name                = "soc-bastion"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_network_security_group" "soc_nsg" {
  name                = "soc-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-Splunk-Web-From-Admin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.admin_source_ip_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Splunk-Ingest-From-AD"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9997"
    source_address_prefix      = var.ad_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Splunk-Ingest-From-Client"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9997"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Splunk-Mgmt-From-Admin"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8089"
    source_address_prefix      = var.admin_source_ip_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "ad_nsg" {
  name                = "ad-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-RDP-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-DNS-TCP-From-Client"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-DNS-UDP-From-Client"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Kerberos-TCP-From-Client"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Kerberos-UDP-From-Client"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "88"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-LDAP-TCP-From-Client"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-LDAP-UDP-From-Client"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "389"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SMB-From-Client"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RPC-Endpoint-Mapper-From-Client"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "135"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Dynamic-RPC-From-Client"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "49152-65535"
    source_address_prefix      = var.client_subnet_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "client_nsg" {
  name                = "client-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-RDP-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.bastion_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                        = "Allow-Client-To-AD-Core-Traffic"
    priority                    = 110
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_ranges     = ["53", "88", "135", "389", "445"]
    source_address_prefix       = "*"
    destination_address_prefix  = var.ad_subnet_cidr
  }

  security_rule {
    name                        = "Allow-Client-To-AD-Kerberos-UDP"
    priority                    = 120
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Udp"
    source_port_range           = "*"
    destination_port_range      = "88"
    source_address_prefix       = "*"
    destination_address_prefix  = var.ad_subnet_cidr
  }

  security_rule {
    name                        = "Allow-Client-To-AD-Dynamic-RPC"
    priority                    = 130
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "49152-65535"
    source_address_prefix       = "*"
    destination_address_prefix  = var.ad_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "soc_assoc" {
  subnet_id                 = azurerm_subnet.soc_subnet.id
  network_security_group_id = azurerm_network_security_group.soc_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "ad_assoc" {
  subnet_id                 = azurerm_subnet.ad_subnet.id
  network_security_group_id = azurerm_network_security_group.ad_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "client_assoc" {
  subnet_id                 = azurerm_subnet.client_subnet.id
  network_security_group_id = azurerm_network_security_group.client_nsg.id
}
