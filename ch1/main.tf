locals {
  location = var.location
}

resource "azurerm_resource_group" "kpmg_rg" {
  name = var.rg_name
  location = local.location
}

resource "azurerm_virtual_network" "kpmg_project1_vpc" {
  name = var.vpc_name
  location = local.location
  address_space = [ var.vpc_address_space ]
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_subnet" "WebSubnet" {
  name = "WebSubnet"
  address_prefixes = [ var.web_subnet_cidr ]
  virtual_network_name = azurerm_virtual_network.kpmg_project1_vpc.name
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_subnet" "AppSubnet" {
  name = "AppSubnet"
  address_prefixes = [ var.app_subnet_cidr ]
  virtual_network_name = azurerm_virtual_network.kpmg_project1_vpc.name
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_subnet" "DbSubnet" {
  name = "DbSubnet"
  address_prefixes = [ var.db_subnet_cidr ]
  virtual_network_name = azurerm_virtual_network.kpmg_project1_vpc.name
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_network_security_group" "web-nsg" {
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  location = local.location
  name = "web-nsg"
  security_rule {
    name = "ssh-rule-1"
    priority = 101
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "22"
  }
  security_rule {
    name = "ssh-rule-2"
    priority = 100
    direction = "Inbound"
    access = "Deny"
    protocol = "Tcp"
    source_address_prefix = var.db_subnet_cidr
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "22"
  }
  security_rule {
    name = "web-rule-1"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "80"
  }
}

resource "azurerm_network_security_group" "app-nsg" {
  name = "app-nsg"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  security_rule {
    name = "ssh-rule-1"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.web_subnet_cidr
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "*" 
  }
  security_rule {
    name = "ssh-rule-2"
    priority = 101
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.web_subnet_cidr
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "22"
  }
  security_rule {
    name = "web-rule-1"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.web_subnet_cidr
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "80"
  }
  security_rule {
    name = "web-rule-2"
    priority = 102
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.web_subnet_cidr
    destination_address_prefix = "*"
    source_port_range = "*"
    destination_port_range = "80"
  }
}

resource "azurerm_network_security_group" "db-nsg" {
  name = "db-nsg"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  security_rule {
    name = "db-rule-1"
    priority = 101
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.app_subnet_cidr
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "3306" 
  }
  security_rule {
    name = "db-rule-2"
    priority = 102
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_address_prefix = var.app_subnet_cidr
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "3306" 
  }
  security_rule {
    name = "db-rule-3"
    priority = 100
    direction = "Outbound"
    access = "Deny"
    protocol = "Tcp"
    source_address_prefix = var.web_subnet_cidr
    source_port_range = "*"
    destination_address_prefix = "*"
    destination_port_range = "3306" 
  }
}

resource "azurerm_subnet_network_security_group_association" "web-nsg-subnet" {
  network_security_group_id = azurerm_network_security_group.web-nsg.id
  subnet_id = azurerm_subnet.WebSubnet.id
}

resource "azurerm_subnet_network_security_group_association" "app-nsg-subnet" {
  network_security_group_id = azurerm_network_security_group.app-nsg.id
  subnet_id = azurerm_subnet.AppSubnet.id
}

resource "azurerm_subnet_network_security_group_association" "db-nsg-subnet" {
  network_security_group_id = azurerm_network_security_group.db-nsg.id
  subnet_id = azurerm_subnet.DbSubnet.id
}

resource "azurerm_network_interface" "web-nic" {
  name = "web-nic"
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  location = local.location
  ip_configuration {
    name = "web-ip-config"
    subnet_id = azurerm_subnet.WebSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "app-nic" {
  name = "app-nic"
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  location = local.location
  ip_configuration {
    name = "app-ip-config"
    subnet_id = azurerm_subnet.WebSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "web-as" {
  name = "web-as"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_availability_set" "app-as" {
  name = "app-as"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
}

resource "azurerm_virtual_machine" "web-vm" {
  name = "web-vm"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  network_interface_ids = [ azurerm_network_interface.web-nic.id ]
  vm_size = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  availability_set_id = azurerm_availability_set.web-as.id
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name = "web-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = var.web_host_name
    admin_username = var.web_username
    admin_password = var.web_os_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine" "app-vm" {
  name = "app-vm"
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  network_interface_ids = [ azurerm_network_interface.app-nic.id ]
  vm_size = "Standard_D2s_v3"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  availability_set_id = azurerm_availability_set.app-as.id
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name = "web-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name = var.app_host_name
    admin_username = var.app_username
    admin_password = var.app_os_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_mssql_server" "db-primary" {
  name = var.sql_server_name
  location = local.location
  resource_group_name = azurerm_resource_group.kpmg_rg.name
  version = var.sql_server_version
  administrator_login = var.sql_server_admin_login
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_mssql_virtual_network_rule" "db-primary-vpc-rule" {
  name = "db-primary-vpc-rule"
  server_id = azurerm_mssql_server.db-primary.id
  subnet_id = azurerm_subnet.DbSubnet.id
}

resource "azurerm_mssql_database" "kpmg-db" {
  name = var.sql_db_name
  server_id = azurerm_mssql_server.db-primary.id
  license_type = "LicenseIncluded"
  max_size_gb = 4
}