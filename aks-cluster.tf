

provider "azurerm" {
  features {}
}
provider "azurerm" {
  features {}
}
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstatefile-rg"
    storage_account_name = "ghtfstatefilesa"
    container_name       = "rgtfstatecontainer"
    key                  = "terraformtemplateDev.tfstate"
  }
}

resource "azurerm_resource_group" "default" {
  name     = "test-k8s-delete-A"
  location = "eastus"

  tags = {
    environment = "Demo"
  }
}


resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.clustername}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${var.clustername}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

