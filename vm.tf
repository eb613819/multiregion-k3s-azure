
# Public IPs

resource "azurerm_public_ip" "pip_a" {
  for_each            = local.nodes_a
  name                = "${var.prefix}-pip-${each.key}"
  location            = var.region_a
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "pip_b" {
  for_each            = local.nodes_b
  name                = "${var.prefix}-pip-${each.key}"
  location            = var.region_b
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NICs

resource "azurerm_network_interface" "nic_a" {
  for_each            = local.nodes_a
  name                = "${var.prefix}-nic-${each.key}"
  location            = var.region_a
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_a.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_a[each.key].id
  }
}

resource "azurerm_network_interface" "nic_b" {
  for_each            = local.nodes_b
  name                = "${var.prefix}-nic-${each.key}"
  location            = var.region_b
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_b.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_b[each.key].id
  }
}

# NSG associations

resource "azurerm_network_interface_security_group_association" "nsg_assoc_a" {
  for_each                  = local.nodes_a
  network_interface_id      = azurerm_network_interface.nic_a[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg_a.id
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_b" {
  for_each                  = local.nodes_b
  network_interface_id      = azurerm_network_interface.nic_b[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg_b.id
}

# VMs - Region A

resource "azurerm_linux_virtual_machine" "vm_a" {
  for_each            = local.nodes_a
  name                = "${var.prefix}-${each.key}"
  location            = var.region_a
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic_a[each.key].id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_pub_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  tags = {
    role = each.value.role
  }
}

# VMs - Region B

resource "azurerm_linux_virtual_machine" "vm_b" {
  for_each            = local.nodes_b
  name                = "${var.prefix}-${each.key}"
  location            = var.region_b
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic_b[each.key].id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_pub_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  tags = {
    role = each.value.role
  }
}