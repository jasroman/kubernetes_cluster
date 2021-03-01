#Version del proveedor de azure y referencias a otros modulos
provider "azurerm" {
  version =  "1.35.0"
}

module "basic" {
  source = "../globales"
}

