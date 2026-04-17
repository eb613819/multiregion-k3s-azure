
# Resource group

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.region_a
}

# VNet for Region A

resource "azurerm_virtual_network" "vnet_a" {
  name                = "${var.prefix}-vnet-a"
  location            = var.region_a
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_a" {
  name                 = "${var.prefix}-subnet-a"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_a.name
  address_prefixes     = ["10.0.1.0/24"]
}

# VNet for Region B

resource "azurerm_virtual_network" "vnet_b" {
  name                = "${var.prefix}-vnet-b"
  location            = var.region_b
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet_b" {
  name                 = "${var.prefix}-subnet-b"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_b.name
  address_prefixes     = ["10.1.1.0/24"]
}

# VNet Peering

resource "azurerm_virtual_network_peering" "peer_a_to_b" {
  name                      = "peer-a-to-b"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_a.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_b.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "peer_b_to_a" {
  name                      = "peer-b-to-a"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_b.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_a.id
  allow_forwarded_traffic   = true
}

# Network Security Groups

resource "azurerm_network_security_group" "nsg_a" {
  name                = "${var.prefix}-nsg-a"
  location            = var.region_a
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = local.k3s_nsg_rules

    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = security_rule.value.source
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_network_security_group" "nsg_b" {
  name                = "${var.prefix}-nsg-b"
  location            = var.region_b
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = local.k3s_nsg_rules

    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = security_rule.value.source
      destination_address_prefix = "*"
    }
  }
}