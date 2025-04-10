resource "azurerm_resource_group" "cats" {
  name     = "cats-app-rg"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "catsacr${substr(sha256(azurerm_resource_group.cats.name), 0, 8)}"
  resource_group_name = azurerm_resource_group.cats.name
  location            = azurerm_resource_group.cats.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "cats-aks"
  location            = azurerm_resource_group.cats.location
  resource_group_name = azurerm_resource_group.cats.name
  dns_prefix          = "catsaks"
  
  default_node_pool {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_B2s"
    auto_scaling_enabled = true
    min_count           = 3
    max_count           = 5
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}