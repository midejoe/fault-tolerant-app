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


resource "azurerm_monitor_workspace" "cats" {
  name                = "cats-monitor"
  resource_group_name = azurerm_resource_group.cats.name
  location            = azurerm_resource_group.cats.location
}

## ---------------------------------------------------
# Managed Grafana
## ---------------------------------------------------
resource "azurerm_dashboard_grafana" "catsacrboard" {
  name                              = "graf-prod-cat"
  resource_group_name               = azurerm_resource_group.cats.name
  location                          = azurerm_resource_group.cats.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  grafana_major_version = 11
  identity {
    type = "SystemAssigned"
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.cats.id
  }
}
 
# Add required role assignment over resource group containing the Azure Monitor Workspace
resource "azurerm_role_assignment" "grafana" {
  scope                = azurerm_resource_group.cats.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.catsacrboard.identity[0].principal_id
}
 
# Add role assignment to Grafana so an admin user can log in
# resource "azurerm_role_assignment" "grafana-admin" {
#   scope                = azurerm_dashboard_grafana.catsacrboard.id
#   role_definition_name = "Grafana Admin"
#   principal_id         = var.adminGroupObjectIds[0]
# }

# variable "adminGroupObjectIds" {
#   type        = list(string)
#   description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster"
#   default     = []
# }
 

