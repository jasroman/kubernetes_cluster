#Creamos la ip publica del master
resource "azurerm_public_ip" "master_pip" {
  name                = "${var.prefix}-master-pip"
  resource_group_name = module.network.resource-group-name
  location            = "${module.basic.location}"
  allocation_method   = "Static"
}

#Creamos el interfaz de red del master
resource "azurerm_network_interface" "nic-master" {
  name                            = "${var.prefix-master}-nic"
  location                        = "${module.basic.location}"
  resource_group_name             = "${module.network.resource-group-name}"
  network_security_group_id       = module.network.network-nsg-id

  ip_configuration {
    name                          = "${var.prefix-master}-ip-1"
    subnet_id                     = "${module.network.network-subnet-id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.master_pip.id}"
  }
}

#Creamos la máquina Ubuntu del master, se elige de tipo A2 por la restriccion de la cuenta de tener 4 cores de tipo B
resource "azurerm_virtual_machine" "vm-master" {
  name                  = "${var.prefix-master}"
  location              = "${module.basic.location}"
  resource_group_name   = "${module.network.resource-group-name}"
  network_interface_ids = ["${azurerm_network_interface.nic-master.id}"]
  vm_size               = "Standard_A2_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix-master}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "master"
    admin_username = "${var.admin-user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin-user}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }

  }

}

#Posibilitamos el acceso por ssh con la clave publico/privada
resource "null_resource" "vm-ssh-keys-master" {

  depends_on = [azurerm_virtual_machine.vm-master]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.master_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa.pub"

    destination = "~/.ssh/id_rsa.pub"

  }
}

resource "null_resource" "vm-priv-ssh-keys-master" {

  depends_on = [azurerm_virtual_machine.vm-master]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.master_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa"

    destination = "~/.ssh/id_rsa"

  }
}
