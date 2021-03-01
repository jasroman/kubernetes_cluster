#Creamos la ip publica de w2
resource "azurerm_public_ip" "worker-2_pip" {
  name                = "${var.prefix}-worker2-pip"
  resource_group_name = module.network.resource-group-name
  location            = "${module.basic.location}"
  allocation_method   = "Static"
}

#Creamos la interfaz de red de w2
resource "azurerm_network_interface" "nic-worker-2" {
  name                            = "${var.prefix-worker-2}-nic"
  location                        = "${module.basic.location}"
  resource_group_name             = "${module.network.resource-group-name}"
  network_security_group_id       = module.network.network-nsg-id

  ip_configuration {
    name                          = "${var.prefix-worker-2}-ip-1"
    subnet_id                     = "${module.network.network-subnet-id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.worker-2_pip.id}"
  }
}

#Creamos la vm del w2. Worker-1 y worker-2 tienen vm de tipo B2
resource "azurerm_virtual_machine" "vm-worker-2" {
  name                  = "${var.prefix-worker-2}"
  location              = "${module.basic.location}"
  resource_group_name   = "${module.network.resource-group-name}"
  network_interface_ids = ["${azurerm_network_interface.nic-worker-2.id}"]
  vm_size               = "Standard_B2s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix-worker-2}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "worker-2"
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

#Posibilitamos el acceso por ssh mediante clave publico/privada
resource "null_resource" "vm-ssh-keys-worker-2" {

  depends_on = [azurerm_virtual_machine.vm-worker-2]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.worker-2_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa.pub"

    destination = "~/.ssh/id_rsa.pub"

  }
}

resource "null_resource" "vm-priv-ssh-keys-worker-2" {

  depends_on = [azurerm_virtual_machine.vm-worker-2]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.worker-2_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa"

    destination = "~/.ssh/id_rsa"

  }
}
