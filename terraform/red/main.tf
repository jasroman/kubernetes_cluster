#Creamos el grupo de recursos
resource "azurerm_resource_group" "k8s-resources" {
  name     = "${var.prefix}-${module.basic.resource_group}"
  location = module.basic.location
}

#Creamos la red virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = module.basic.location
  resource_group_name = azurerm_resource_group.k8s-resources.name
}

#Creamos la subred, sobre esta subred se vincularan todas la ip_configuration de los interfaces de red de los nodos
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-network-subnet"
  resource_group_name  = azurerm_resource_group.k8s-resources.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.0.2.0/24"
}

#Creamos el grupo de seguridad y reglas de proteccion
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = module.basic.location
  resource_group_name = azurerm_resource_group.k8s-resources.name
}

#Limitamos ssh a la maquina desde que se lancen los scripts de terraform
resource "azurerm_network_security_rule" "nsg-inbound" {
  name                        = "${var.prefix}-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.k8s-resources.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg-inbound-http" {
  name                        = "${var.prefix}-http"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.k8s-resources.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg-inbound-http-2" {
  name                        = "${var.prefix}-http-2"
  priority                    = 131
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30000-40000"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.k8s-resources.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg-inbound-https" {
        name                       = "${var.prefix}-out-allow"
        priority                   = 120
        access                     = "allow"
        protocol                   = "Tcp"
        direction                  = "Inbound"
        source_address_prefix      = "*"
        destination_address_prefix = "AzureCloud"
        source_port_range          = "*"
        destination_port_range     = "443"
        resource_group_name         = azurerm_resource_group.k8s-resources.name
  	network_security_group_name = azurerm_network_security_group.nsg.name
}


resource "azurerm_network_security_rule" "nsg-inbound-rdp" {
      name                       = "${var.prefix}-rdp"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "4443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
      resource_group_name         = azurerm_resource_group.k8s-resources.name
      network_security_group_name = azurerm_network_security_group.nsg.name    
}      

#Vinculamos la subred y el grupo de seguridad, con todas sus reglas anteriores
resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
