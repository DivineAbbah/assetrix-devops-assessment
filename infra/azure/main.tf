terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "assetrix_rg" {
  name     = "assetrix-assessment-rg"
  location = var.location
}

resource "azurerm_virtual_network" "assetrix_vnet" {
  name                = "assetrix-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.assetrix_rg.location
  resource_group_name = azurerm_resource_group.assetrix_rg.name
}

resource "azurerm_subnet" "assetrix_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.assetrix_rg.name
  virtual_network_name = azurerm_virtual_network.assetrix_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP to access the VM
resource "azurerm_public_ip" "assetrix_pip" {
  name                = "assetrix-pip"
  resource_group_name = azurerm_resource_group.assetrix_rg.name
  location            = azurerm_resource_group.assetrix_rg.location
  allocation_method   = "Dynamic"
}

# Network Interface with Public IP
resource "azurerm_network_interface" "assetrix_nic" {
  name                = "assertrix-nic"
  location            = azurerm_resource_group.assetrix_rg.location
  resource_group_name = azurerm_resource_group.assetrix_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.assetrix_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.assetrix_pip.id
  }
}

# Network Security Group to allow HTTP and SSH
resource "azurerm_network_security_group" "assetrix_nsg" {
  name                = "assertrix-nsg"
  location            = azurerm_resource_group.assetrix_rg.location
  resource_group_name = azurerm_resource_group.assetrix_rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.assetrix_nic.id
  network_security_group_id = azurerm_network_security_group.assetrix_nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "assetrix_vm" {
  name                = "assetrix-app-vm"
  resource_group_name = azurerm_resource_group.assetrix_rg.name
  location            = azurerm_resource_group.assetrix_rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.assetrix_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Use Cloud-Init to install Docker and run the container
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
  dockerhub_username = var.dockerhub_username
  dockerhub_token    = var.dockerhub_token
  docker_image       = var.docker_image
  image_tag          = var.image_tag
}))
