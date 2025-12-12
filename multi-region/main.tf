# ============================================================================
# Multi-Region Azure Cosmos DB Infrastructure with AKS
# ============================================================================
# This Terraform configuration deploys a highly available, multi-region
# Azure Cosmos DB setup with AKS clusters, private networking, and
# workload identity integration across East US 2 and West US 2
# ============================================================================

# ----------------------------------------------------------------------------
# Resource Groups
# ----------------------------------------------------------------------------

# Primary region resource group (East US 2)
resource "azurerm_resource_group" "primary" {
  name     = "${var.project_name}-${var.environment}-rg-${var.location_primary}"
  location = var.location_primary
  tags     = var.tags
}

# Secondary region resource group (West US 2)
resource "azurerm_resource_group" "secondary" {
  name     = "${var.project_name}-${var.environment}-rg-${var.location_secondary}"
  location = var.location_secondary
  tags     = var.tags
}

# ----------------------------------------------------------------------------
# Azure Container Registry (ACR)
# ----------------------------------------------------------------------------

# Container registry for storing Docker images
resource "azurerm_container_registry" "main" {
  name                = replace("${var.project_name}${var.environment}acr", "-", "")
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = var.tags
}

# Attach ACR to primary AKS cluster
resource "azurerm_role_assignment" "aks_primary_acr" {
  principal_id                     = azurerm_kubernetes_cluster.primary.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# Attach ACR to secondary AKS cluster
resource "azurerm_role_assignment" "aks_secondary_acr" {
  principal_id                     = azurerm_kubernetes_cluster.secondary.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# ----------------------------------------------------------------------------
# Virtual Networks - Primary Region (East US 2)
# ----------------------------------------------------------------------------

# AKS VNet in primary region
resource "azurerm_virtual_network" "primary_aks" {
  name                = "${var.project_name}-${var.environment}-vnet-aks-${var.location_primary}"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  address_space       = [var.vnet_address_spaces.primary_aks]
  tags                = var.tags
}

# AKS subnet in primary region
resource "azurerm_subnet" "primary_aks" {
  name                 = "${var.project_name}-${var.environment}-subnet-aks-${var.location_primary}"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary_aks.name
  address_prefixes     = [var.subnet_address_prefixes.primary_aks_subnet]
}

# Cosmos DB VNet in primary region
resource "azurerm_virtual_network" "primary_cosmosdb" {
  name                = "${var.project_name}-${var.environment}-vnet-cosmosdb-${var.location_primary}"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  address_space       = [var.vnet_address_spaces.primary_cosmosdb]
  tags                = var.tags
}

# Cosmos DB private endpoint subnet in primary region
resource "azurerm_subnet" "primary_cosmosdb" {
  name                 = "${var.project_name}-${var.environment}-subnet-cosmosdb-${var.location_primary}"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary_cosmosdb.name
  address_prefixes     = [var.subnet_address_prefixes.primary_cosmosdb_subnet]
}

# ----------------------------------------------------------------------------
# Virtual Networks - Secondary Region (West US 2)
# ----------------------------------------------------------------------------

# AKS VNet in secondary region
resource "azurerm_virtual_network" "secondary_aks" {
  name                = "${var.project_name}-${var.environment}-vnet-aks-${var.location_secondary}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  address_space       = [var.vnet_address_spaces.secondary_aks]
  tags                = var.tags
}

# AKS subnet in secondary region
resource "azurerm_subnet" "secondary_aks" {
  name                 = "${var.project_name}-${var.environment}-subnet-aks-${var.location_secondary}"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.secondary_aks.name
  address_prefixes     = [var.subnet_address_prefixes.secondary_aks_subnet]
}

# Cosmos DB VNet in secondary region
resource "azurerm_virtual_network" "secondary_cosmosdb" {
  name                = "${var.project_name}-${var.environment}-vnet-cosmosdb-${var.location_secondary}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  address_space       = [var.vnet_address_spaces.secondary_cosmosdb]
  tags                = var.tags
}

# Cosmos DB private endpoint subnet in secondary region
resource "azurerm_subnet" "secondary_cosmosdb" {
  name                 = "${var.project_name}-${var.environment}-subnet-cosmosdb-${var.location_secondary}"
  resource_group_name  = azurerm_resource_group.secondary.name
  virtual_network_name = azurerm_virtual_network.secondary_cosmosdb.name
  address_prefixes     = [var.subnet_address_prefixes.secondary_cosmosdb_subnet]
}

# ----------------------------------------------------------------------------
# VNet Peering - Primary Region (East US 2)
# ----------------------------------------------------------------------------

# Peering from AKS VNet to Cosmos DB VNet in primary region
resource "azurerm_virtual_network_peering" "primary_aks_to_cosmosdb" {
  name                      = "${var.project_name}-${var.environment}-peer-aks-to-cosmosdb-${var.location_primary}"
  resource_group_name       = azurerm_resource_group.primary.name
  virtual_network_name      = azurerm_virtual_network.primary_aks.name
  remote_virtual_network_id = azurerm_virtual_network.primary_cosmosdb.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# Peering from Cosmos DB VNet to AKS VNet in primary region (bidirectional)
resource "azurerm_virtual_network_peering" "primary_cosmosdb_to_aks" {
  name                      = "${var.project_name}-${var.environment}-peer-cosmosdb-to-aks-${var.location_primary}"
  resource_group_name       = azurerm_resource_group.primary.name
  virtual_network_name      = azurerm_virtual_network.primary_cosmosdb.name
  remote_virtual_network_id = azurerm_virtual_network.primary_aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# ----------------------------------------------------------------------------
# VNet Peering - Secondary Region (West US 2)
# ----------------------------------------------------------------------------

# Peering from AKS VNet to Cosmos DB VNet in secondary region
resource "azurerm_virtual_network_peering" "secondary_aks_to_cosmosdb" {
  name                      = "${var.project_name}-${var.environment}-peer-aks-to-cosmosdb-${var.location_secondary}"
  resource_group_name       = azurerm_resource_group.secondary.name
  virtual_network_name      = azurerm_virtual_network.secondary_aks.name
  remote_virtual_network_id = azurerm_virtual_network.secondary_cosmosdb.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# Peering from Cosmos DB VNet to AKS VNet in secondary region (bidirectional)
resource "azurerm_virtual_network_peering" "secondary_cosmosdb_to_aks" {
  name                      = "${var.project_name}-${var.environment}-peer-cosmosdb-to-aks-${var.location_secondary}"
  resource_group_name       = azurerm_resource_group.secondary.name
  virtual_network_name      = azurerm_virtual_network.secondary_cosmosdb.name
  remote_virtual_network_id = azurerm_virtual_network.secondary_aks.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# ----------------------------------------------------------------------------
# Azure Cosmos DB Account (Multi-Region)
# ----------------------------------------------------------------------------

# Multi-region Cosmos DB account with zone redundancy and private networking
resource "azurerm_cosmosdb_account" "main" {
  name                = var.cosmosdb_account_name
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # SQL API

  # Enable multi-region writes (active-active configuration)
  multiple_write_locations_enabled = var.enable_multi_region_writes

  # Automatic failover for high availability
  automatic_failover_enabled = true

  # Consistency policy - Eventual consistency for low latency
  consistency_policy {
    consistency_level       = var.cosmosdb_consistency_level
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  # Primary region configuration with zone redundancy
  geo_location {
    location          = var.location_primary
    failover_priority = 0
    zone_redundant    = var.enable_zone_redundancy # 99.995% SLA
  }

  # Secondary region configuration with zone redundancy
  geo_location {
    location          = var.location_secondary
    failover_priority = 1
    zone_redundant    = var.enable_zone_redundancy # 99.995% SLA
  }

  # Security settings - Azure AD authentication only, no public access
  public_network_access_enabled         = var.public_network_access_enabled
  is_virtual_network_filter_enabled     = true
  local_authentication_disabled         = true # Azure AD only, no key-based auth
  network_acl_bypass_for_azure_services = true
  minimal_tls_version                   = "Tls12" # Enforce TLS 1.2 minimum

  # Continuous backup for point-in-time restore
  backup {
    type = "Continuous"
    tier = "Continuous7Days"
  }

  tags = var.tags
}

# ----------------------------------------------------------------------------
# Cosmos DB SQL Database
# ----------------------------------------------------------------------------

# SQL database with autoscale throughput
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name

  # Autoscale throughput configuration (1,000 - 10,000 RU/s)
  autoscale_settings {
    max_throughput = var.cosmosdb_autoscale_max_throughput
  }
}

# ----------------------------------------------------------------------------
# Cosmos DB SQL Container
# ----------------------------------------------------------------------------

# Container with partition key and autoscale
resource "azurerm_cosmosdb_sql_container" "threads" {
  name                  = var.cosmosdb_container_name
  resource_group_name   = azurerm_cosmosdb_account.main.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths   = [var.cosmosdb_partition_key]
  partition_key_version = 2 # Latest partition key version

  # Indexing policy for optimized queries
  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }

  # Default TTL disabled (items don't expire)
  default_ttl = -1
}

# ----------------------------------------------------------------------------
# Private DNS Zones for Cosmos DB (per region)
# ----------------------------------------------------------------------------

# Private DNS zone for Cosmos DB in primary region (East US 2)
resource "azurerm_private_dns_zone" "cosmosdb_primary" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags
}

# Private DNS zone for Cosmos DB in secondary region (West US 2)
resource "azurerm_private_dns_zone" "cosmosdb_secondary" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.secondary.name
  tags                = var.tags
}

# Link primary DNS zone to primary AKS VNet only
resource "azurerm_private_dns_zone_virtual_network_link" "primary_aks" {
  name                  = "${var.project_name}-${var.environment}-dns-link-aks-${var.location_primary}"
  resource_group_name   = azurerm_resource_group.primary.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_primary.name
  virtual_network_id    = azurerm_virtual_network.primary_aks.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link primary DNS zone to primary Cosmos DB VNet only
resource "azurerm_private_dns_zone_virtual_network_link" "primary_cosmosdb" {
  name                  = "${var.project_name}-${var.environment}-dns-link-cosmosdb-${var.location_primary}"
  resource_group_name   = azurerm_resource_group.primary.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_primary.name
  virtual_network_id    = azurerm_virtual_network.primary_cosmosdb.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link secondary DNS zone to secondary AKS VNet only
resource "azurerm_private_dns_zone_virtual_network_link" "secondary_aks" {
  name                  = "${var.project_name}-${var.environment}-dns-link-aks-${var.location_secondary}"
  resource_group_name   = azurerm_resource_group.secondary.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_secondary.name
  virtual_network_id    = azurerm_virtual_network.secondary_aks.id
  registration_enabled  = false
  tags                  = var.tags
}

# Link secondary DNS zone to secondary Cosmos DB VNet only
resource "azurerm_private_dns_zone_virtual_network_link" "secondary_cosmosdb" {
  name                  = "${var.project_name}-${var.environment}-dns-link-cosmosdb-${var.location_secondary}"
  resource_group_name   = azurerm_resource_group.secondary.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_secondary.name
  virtual_network_id    = azurerm_virtual_network.secondary_cosmosdb.id
  registration_enabled  = false
  tags                  = var.tags
}

# ----------------------------------------------------------------------------
# Private Endpoints for Cosmos DB
# ----------------------------------------------------------------------------

# Private endpoint for Cosmos DB in primary region
resource "azurerm_private_endpoint" "cosmosdb_primary" {
  name                = "${var.project_name}-${var.environment}-pe-cosmosdb-${var.location_primary}"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  subnet_id           = azurerm_subnet.primary_cosmosdb.id

  private_service_connection {
    name                           = "${var.project_name}-${var.environment}-psc-cosmosdb-${var.location_primary}"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group-primary"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_primary.id]
  }

  tags = var.tags

  depends_on = [
    azurerm_cosmosdb_account.main
  ]
}

# Private endpoint for Cosmos DB in secondary region
resource "azurerm_private_endpoint" "cosmosdb_secondary" {
  name                = "${var.project_name}-${var.environment}-pe-cosmosdb-${var.location_secondary}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  subnet_id           = azurerm_subnet.secondary_cosmosdb.id

  private_service_connection {
    name                           = "${var.project_name}-${var.environment}-psc-cosmosdb-${var.location_secondary}"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group-secondary"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_secondary.id]
  }

  tags = var.tags

  depends_on = [
    azurerm_cosmosdb_account.main
  ]
}

# ----------------------------------------------------------------------------
# User-Assigned Managed Identities for AKS Workloads
# ----------------------------------------------------------------------------

# Managed identity for primary AKS workloads
resource "azurerm_user_assigned_identity" "aks_primary" {
  name                = "${var.project_name}-${var.environment}-id-aks-${var.location_primary}"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags
}

# Managed identity for secondary AKS workloads
resource "azurerm_user_assigned_identity" "aks_secondary" {
  name                = "${var.project_name}-${var.environment}-id-aks-${var.location_secondary}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  tags                = var.tags
}

# ----------------------------------------------------------------------------
# AKS Clusters
# ----------------------------------------------------------------------------

# Primary AKS cluster (East US 2)
resource "azurerm_kubernetes_cluster" "primary" {
  name                = "${var.project_name}-${var.environment}-aks-${var.location_primary}"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  dns_prefix          = "${var.project_name}-${var.environment}-aks-${var.location_primary}"
  kubernetes_version  = var.kubernetes_version

  # Default node pool configuration
  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = azurerm_subnet.primary_aks.id
    zones               = ["1", "2", "3"] # Zone-redundant deployment
    os_disk_size_gb     = 30
  }

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile with Azure CNI
  network_profile {
    network_plugin    = var.aks_network_plugin
    network_policy    = var.aks_network_policy
    service_cidr      = var.aks_service_cidrs.primary
    dns_service_ip    = var.aks_dns_service_ips.primary
    load_balancer_sku = "standard"
  }

  # Workload identity configuration
  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  tags = var.tags
}

# Secondary AKS cluster (West US 2)
resource "azurerm_kubernetes_cluster" "secondary" {
  name                = "${var.project_name}-${var.environment}-aks-${var.location_secondary}"
  location            = azurerm_resource_group.secondary.location
  resource_group_name = azurerm_resource_group.secondary.name
  dns_prefix          = "${var.project_name}-${var.environment}-aks-${var.location_secondary}"
  kubernetes_version  = var.kubernetes_version

  # Default node pool configuration
  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = azurerm_subnet.secondary_aks.id
    zones               = ["1", "2", "3"] # Zone-redundant deployment
    os_disk_size_gb     = 30
  }

  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile with Azure CNI
  network_profile {
    network_plugin    = var.aks_network_plugin
    network_policy    = var.aks_network_policy
    service_cidr      = var.aks_service_cidrs.secondary
    dns_service_ip    = var.aks_dns_service_ips.secondary
    load_balancer_sku = "standard"
  }

  # Workload identity configuration
  oidc_issuer_enabled       = var.enable_workload_identity
  workload_identity_enabled = var.enable_workload_identity

  tags = var.tags
}

# ----------------------------------------------------------------------------
# Federated Identity Credentials for Workload Identity
# ----------------------------------------------------------------------------

# Federated credential for primary AKS cluster
resource "azurerm_federated_identity_credential" "aks_primary" {
  name                = "${var.project_name}-${var.environment}-fic-aks-${var.location_primary}"
  resource_group_name = azurerm_resource_group.primary.name
  parent_id           = azurerm_user_assigned_identity.aks_primary.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.primary.oidc_issuer_url
  subject             = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
}

# Federated credential for secondary AKS cluster
resource "azurerm_federated_identity_credential" "aks_secondary" {
  name                = "${var.project_name}-${var.environment}-fic-aks-${var.location_secondary}"
  resource_group_name = azurerm_resource_group.secondary.name
  parent_id           = azurerm_user_assigned_identity.aks_secondary.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.secondary.oidc_issuer_url
  subject             = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_service_account}"
}

# ----------------------------------------------------------------------------
# Azure Container Registry
# ----------------------------------------------------------------------------

# ACR in primary region (both AKS clusters will use this)
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identity for authentication
  tags                = var.tags
}

# Grant AcrPull role to primary AKS kubelet identity
resource "azurerm_role_assignment" "aks_primary_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.primary.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

# Grant AcrPull role to secondary AKS kubelet identity
resource "azurerm_role_assignment" "aks_secondary_acr_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.secondary.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

# ----------------------------------------------------------------------------
# RBAC Assignments - Cosmos DB Built-in Data Contributor
# ----------------------------------------------------------------------------

# Assign Cosmos DB Built-in Data Contributor role to primary managed identity
resource "azurerm_cosmosdb_sql_role_assignment" "primary" {
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  # Cosmos DB Built-in Data Contributor role ID
  role_definition_id = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = azurerm_user_assigned_identity.aks_primary.principal_id
  scope              = azurerm_cosmosdb_account.main.id
}

# Assign Cosmos DB Built-in Data Contributor role to secondary managed identity
resource "azurerm_cosmosdb_sql_role_assignment" "secondary" {
  resource_group_name = azurerm_cosmosdb_account.main.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  # Cosmos DB Built-in Data Contributor role ID
  role_definition_id = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id       = azurerm_user_assigned_identity.aks_secondary.principal_id
  scope              = azurerm_cosmosdb_account.main.id
}
