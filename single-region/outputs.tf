# ============================================================================
# Terraform Outputs - Single Region
# ============================================================================

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region"
  value       = azurerm_resource_group.main.location
}

# Cosmos DB
output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_endpoint" {
  description = "Endpoint URL for Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_database_name" {
  description = "Name of the Cosmos DB database"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "cosmosdb_container_name" {
  description = "Name of the Cosmos DB container"
  value       = azurerm_cosmosdb_sql_container.main.name
}

output "cosmosdb_private_endpoint_ip" {
  description = "Private IP address of the Cosmos DB private endpoint"
  value       = azurerm_private_endpoint.cosmosdb.private_service_connection[0].private_ip_address
}

# AKS
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "aks_kube_config" {
  description = "Kubernetes configuration for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

# Managed Identity
output "managed_identity_client_id" {
  description = "Client ID of the managed identity for workload identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = azurerm_user_assigned_identity.aks.id
}

# Network
output "vnet_aks_id" {
  description = "ID of the AKS VNet"
  value       = azurerm_virtual_network.aks.id
}

output "vnet_cosmosdb_id" {
  description = "ID of the Cosmos DB VNet"
  value       = azurerm_virtual_network.cosmosdb.id
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.cosmosdb.name
}

# Helper Commands
output "kubeconfig_command" {
  description = "Command to get AKS cluster credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

# Container Registry
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "kubernetes_service_account_annotation" {
  description = "Annotation to add to Kubernetes service account for workload identity"
  value = {
    "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks.client_id
  }
}
