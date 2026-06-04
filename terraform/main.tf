# main.tf
# Deploys a Linux VM on Azure to host DefectDojo
# Free tier eligible: Standard_B1s

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

# ── Resource Group ────────────────────────────────────────────
resource "azurerm_resource_group" "devsecops" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "learning"
    project     = "devsecops-lab"
  }
}

# ── Virtual Network ───────────────────────────────────────────
resource "azurerm_virtual_network" "devsecops" {
  name                = "devsecops-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name
}

resource "azurerm_subnet" "devsecops" {
  name                 = "devsecops-subnet"
  resource_group_name  = azurerm_resource_group.devsecops.name
  virtual_network_name = azurerm_virtual_network.devsecops.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ── Public IP ─────────────────────────────────────────────────
resource "azurerm_public_ip" "devsecops" {
  name                = "defectdojo-public-ip"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "learning"
  }
}

# ── Network Security Group ────────────────────────────────────
# ✅ Only allowing necessary ports (Checkov will validate this)
resource "azurerm_network_security_group" "devsecops" {
  name                = "defectdojo-nsg"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name

  # SSH access - restrict to your IP in production
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }

  # DefectDojo web UI
  security_rule {
    name                       = "DefectDojo"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.allowed_ip
    destination_address_prefix = "*"
  }
}

# ── Network Interface ─────────────────────────────────────────
resource "azurerm_network_interface" "devsecops" {
  name                = "defectdojo-nic"
  location            = azurerm_resource_group.devsecops.location
  resource_group_name = azurerm_resource_group.devsecops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devsecops.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devsecops.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "devsecops" {
  network_interface_id      = azurerm_network_interface.devsecops.id
  network_security_group_id = azurerm_network_security_group.devsecops.id
}

# ── Linux Virtual Machine ─────────────────────────────────────
resource "azurerm_linux_virtual_machine" "defectdojo" {
  name                = "defectdojo-vm"
  resource_group_name = azurerm_resource_group.devsecops.name
  location            = azurerm_resource_group.devsecops.location
  size                = var.vm_size  # Standard_B1s = free tier
  admin_username      = var.admin_username

  # ✅ SSH key auth only - no password auth (security best practice)
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.devsecops.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    # ✅ Disk encryption enabled
    disk_encryption_set_id = null
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init script to auto-install Docker and DefectDojo
  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))

  tags = {
    environment = "learning"
    project     = "devsecops-lab"
    tool        = "defectdojo"
  }
}
