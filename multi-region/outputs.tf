# ============================================================================
# Terraform Outputs
# ============================================================================
# This file defines output values for the multi-region Cosmos DB infrastructure
# including connection strings, cluster credentials, and resource identifiers
# ============================================================================

# ----------------------------------------------------------------------------
# Azure Container Registry Outputs
# ----------------------------------------------------------------------------

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

# ----------------------------------------------------------------------------
# Cosmos DB Outputs
# ----------------------------------------------------------------------------

output "cosmosdb_account_name" {
  description = "Name of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmosdb_account_id" {
  description = "Resource ID of the Cosmos DB account"
  value       = azurerm_cosmosdb_account.main.id
}

output "cosmosdb_endpoint" {
  description = "Cosmos DB account endpoint URL"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database"
  value       = azurerm_cosmosdb_sql_database.main.name
}

output "cosmosdb_container_name" {
  description = "Name of the Cosmos DB container"
  value       = azurerm_cosmosdb_sql_container.threads.name
}

output "cosmosdb_read_endpoints" {
  description = "List of read endpoints for all Cosmos DB regions"
  value       = azurerm_cosmosdb_account.main.read_endpoints
}

output "cosmosdb_write_endpoints" {
  description = "List of write endpoints for all Cosmos DB regions"
  value       = azurerm_cosmosdb_account.main.write_endpoints
}

# ----------------------------------------------------------------------------
# Private Endpoint Outputs
# ----------------------------------------------------------------------------

output "cosmosdb_private_endpoint_primary_ip" {
  description = "Private IP address of Cosmos DB private endpoint in primary region"
  value       = azurerm_private_endpoint.cosmosdb_primary.private_service_connection[0].private_ip_address
}

output "cosmosdb_private_endpoint_secondary_ip" {
  description = "Private IP address of Cosmos DB private endpoint in secondary region"
  value       = azurerm_private_endpoint.cosmosdb_secondary.private_service_connection[0].private_ip_address
}

output "cosmosdb_private_dns_zone_primary_name" {
  description = "Name of the Private DNS zone for Cosmos DB in primary region"
  value       = azurerm_private_dns_zone.cosmosdb_primary.name
}

output "cosmosdb_private_dns_zone_secondary_name" {
  description = "Name of the Private DNS zone for Cosmos DB in secondary region"
  value       = azurerm_private_dns_zone.cosmosdb_secondary.name
}

# ----------------------------------------------------------------------------
# AKS Cluster Outputs - Primary Region
# ----------------------------------------------------------------------------

output "aks_primary_cluster_name" {
  description = "Name of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.primary.name
}

output "aks_primary_cluster_id" {
  description = "Resource ID of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.primary.id
}

output "aks_primary_fqdn" {
  description = "FQDN of the primary AKS cluster"
  value       = azurerm_kubernetes_cluster.primary.fqdn
}

output "aks_primary_kube_config" {
  description = "Kubernetes configuration for primary AKS cluster (sensitive)"
  value       = azurerm_kubernetes_cluster.primary.kube_config_raw
  sensitive   = true
}

output "aks_primary_oidc_issuer_url" {
  description = "OIDC issuer URL for primary AKS cluster workload identity"
  value       = azurerm_kubernetes_cluster.primary.oidc_issuer_url
}

output "aks_primary_managed_identity_client_id" {
  description = "Client ID of the primary AKS user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aks_primary.client_id
}

output "aks_primary_managed_identity_id" {
  description = "Resource ID of the primary AKS user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aks_primary.id
}

# ----------------------------------------------------------------------------
# AKS Cluster Outputs - Secondary Region
# ----------------------------------------------------------------------------

output "aks_secondary_cluster_name" {
  description = "Name of the secondary AKS cluster"
  value       = azurerm_kubernetes_cluster.secondary.name
}

output "aks_secondary_cluster_id" {
  description = "Resource ID of the secondary AKS cluster"
  value       = azurerm_kubernetes_cluster.secondary.id
}

output "aks_secondary_fqdn" {
  description = "FQDN of the secondary AKS cluster"
  value       = azurerm_kubernetes_cluster.secondary.fqdn
}

output "aks_secondary_kube_config" {
  description = "Kubernetes configuration for secondary AKS cluster (sensitive)"
  value       = azurerm_kubernetes_cluster.secondary.kube_config_raw
  sensitive   = true
}

output "aks_secondary_oidc_issuer_url" {
  description = "OIDC issuer URL for secondary AKS cluster workload identity"
  value       = azurerm_kubernetes_cluster.secondary.oidc_issuer_url
}

output "aks_secondary_managed_identity_client_id" {
  description = "Client ID of the secondary AKS user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aks_secondary.client_id
}

output "aks_secondary_managed_identity_id" {
  description = "Resource ID of the secondary AKS user-assigned managed identity"
  value       = azurerm_user_assigned_identity.aks_secondary.id
}

# ----------------------------------------------------------------------------
# Network Outputs
# ----------------------------------------------------------------------------

output "primary_aks_vnet_id" {
  description = "Resource ID of the primary AKS VNet"
  value       = azurerm_virtual_network.primary_aks.id
}

output "primary_cosmosdb_vnet_id" {
  description = "Resource ID of the primary Cosmos DB VNet"
  value       = azurerm_virtual_network.primary_cosmosdb.id
}

output "secondary_aks_vnet_id" {
  description = "Resource ID of the secondary AKS VNet"
  value       = azurerm_virtual_network.secondary_aks.id
}

output "secondary_cosmosdb_vnet_id" {
  description = "Resource ID of the secondary Cosmos DB VNet"
  value       = azurerm_virtual_network.secondary_cosmosdb.id
}

# ----------------------------------------------------------------------------
# Resource Group Outputs
# ----------------------------------------------------------------------------

output "primary_resource_group_name" {
  description = "Name of the primary region resource group"
  value       = azurerm_resource_group.primary.name
}

output "secondary_resource_group_name" {
  description = "Name of the secondary region resource group"
  value       = azurerm_resource_group.secondary.name
}

# ----------------------------------------------------------------------------
# Quick Reference Commands
# ----------------------------------------------------------------------------

output "kubeconfig_command_primary" {
  description = "Command to configure kubectl for primary AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.primary.name} --name ${azurerm_kubernetes_cluster.primary.name}"
}

output "kubeconfig_command_secondary" {
  description = "Command to configure kubectl for secondary AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.secondary.name} --name ${azurerm_kubernetes_cluster.secondary.name}"
}

output "kubernetes_service_account_annotation_primary" {
  description = "Annotation to add to Kubernetes service account for workload identity (primary)"
  value = {
    "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks_primary.client_id
  }
}

output "kubernetes_service_account_annotation_secondary" {
  description = "Annotation to add to Kubernetes service account for workload identity (secondary)"
  value = {
    "azure.workload.identity/client-id" = azurerm_user_assigned_identity.aks_secondary.client_id
  }
}
