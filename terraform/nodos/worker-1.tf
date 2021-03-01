#Creamos la ip publica del w1
resource "azurerm_public_ip" "worker-1_pip" {
  name                = "${var.prefix}-worker1-pip"
  resource_group_name = module.network.resource-group-name
  location            = "${module.basic.location}"
  allocation_method   = "Static"
}

#Creamos la interfaz de red del w1
resource "azurerm_network_interface" "nic-worker-1" {
  name                            = "${var.prefix-worker-1}-nic"
  location                        = "${module.basic.location}"
  resource_group_name             = "${module.network.resource-group-name}"
  network_security_group_id       = module.network.network-nsg-id

  ip_configuration {
    name                          = "${var.prefix-worker-1}-ip-1"
    subnet_id                     = "${module.network.network-subnet-id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.worker-1_pip.id}"
  }
}

#Creamos la vm del w1. Worker-1 y worker-2 tienen vm de tipo B2
resource "azurerm_virtual_machine" "vm-worker-1" {
  name                  = "${var.prefix-worker-1}"
  location              = "${module.basic.location}"
  resource_group_name   = "${module.network.resource-group-name}"
  network_interface_ids = ["${azurerm_network_interface.nic-worker-1.id}"]
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
    name              = "${var.prefix-worker-1}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "worker-1"
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
resource "null_resource" "vm-ssh-keys-worker-1" {

  depends_on = [azurerm_virtual_machine.vm-worker-1]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.worker-1_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa.pub"

    destination = "~/.ssh/id_rsa.pub"

  }
}

resource "null_resource" "vm-priv-ssh-keys-worker-1" {

  depends_on = [azurerm_virtual_machine.vm-worker-1]
  provisioner "file" {

    connection {
      type = "ssh"
      host = "${azurerm_public_ip.worker-1_pip.ip_address}"
      user = "${var.admin-user}"
      private_key = file("~/.ssh/id_rsa")
    }

    source = "~/.ssh/id_rsa"

    destination = "~/.ssh/id_rsa"

  }
}
