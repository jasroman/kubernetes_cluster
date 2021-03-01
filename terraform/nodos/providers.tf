#Especificamos version del provider de azure y relaciones entre los modulos

provider "azurerm" {
  version =  "1.35.0"
}

module "basic" {
  source = "../globales"
}

module "network" {
  source = "../red"
}
