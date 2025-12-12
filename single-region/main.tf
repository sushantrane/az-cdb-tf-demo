# ============================================================================
# Single-Region Azure Cosmos DB Infrastructure with AKS
# ============================================================================

locals {
  resource_group_name = "${var.project_name}-rg-${var.environment}"
  common_tags = merge(var.tags, {
    Location = var.location
  })
}

# ============================================================================
# Resource Group
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ============================================================================
# Virtual Networks
# ============================================================================

resource "azurerm_virtual_network" "aks" {
  name                = "${var.project_name}-vnet-aks-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_aks_address_space]
  tags                = local.common_tags
}

resource "azurerm_virtual_network" "cosmosdb" {
  name                = "${var.project_name}-vnet-cosmosdb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cosmosdb_address_space]
  tags                = local.common_tags
}

# ============================================================================
# Subnets
# ============================================================================

resource "azurerm_subnet" "aks" {
  name                 = "${var.project_name}-subnet-aks-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.subnet_aks_address_prefix]
}

resource "azurerm_subnet" "cosmosdb" {
  name                 = "${var.project_name}-subnet-cosmosdb-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.cosmosdb.name
  address_prefixes     = [var.subnet_cosmosdb_address_prefix]
}

# ============================================================================
# VNet Peering
# ============================================================================

resource "azurerm_virtual_network_peering" "aks_to_cosmosdb" {
  name                      = "${var.project_name}-peer-aks-to-cosmosdb"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.cosmosdb.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "cosmosdb_to_aks" {
  name                      = "${var.project_name}-peer-cosmosdb-to-aks"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.cosmosdb.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

# ============================================================================
# Cosmos DB Account
# ============================================================================

resource "azurerm_cosmosdb_account" "main" {
  name                = var.cosmosdb_account_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = var.cosmosdb_consistency_level
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
    zone_redundant    = var.enable_zone_redundancy
  }

  backup {
    type                = "Continuous"
    tier                = "Continuous7Days"
    interval_in_minutes = var.cosmosdb_backup_interval_minutes
    retention_in_hours  = var.cosmosdb_backup_retention_hours
  }

  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true
  local_authentication_disabled     = true
  
  minimal_tls_version = "Tls12"

  tags = local.common_tags
}

# ============================================================================
# Cosmos DB Database
# ============================================================================

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

# ============================================================================
# Cosmos DB Container
# ============================================================================

resource "azurerm_cosmosdb_sql_container" "main" {
  name                  = var.cosmosdb_container_name
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths   = [var.cosmosdb_partition_key]
  partition_key_version = 2

  autoscale_settings {
    max_throughput = var.cosmosdb_autoscale_max_throughput
  }

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# ============================================================================
# Private DNS Zone
# ============================================================================

resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# ============================================================================
# Private DNS Zone VNet Links
# ============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "${var.project_name}-dns-link-aks"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  virtual_network_id    = azurerm_virtual_network.aks.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "${var.project_name}-dns-link-cosmosdb"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  virtual_network_id    = azurerm_virtual_network.cosmosdb.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# ============================================================================
# Private Endpoint
# ============================================================================

resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "${var.project_name}-pe-cosmosdb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.cosmosdb.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "${var.project_name}-psc-cosmosdb"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmosdb-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb.id]
  }
}

# ============================================================================
# User-Assigned Managed Identity for AKS
# ============================================================================

resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.project_name}-id-aks-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# ============================================================================
# AKS Cluster
# ============================================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                              = "${var.project_name}-aks-${var.environment}"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  dns_prefix                        = "${var.project_name}-aks-${var.environment}"
  kubernetes_version                = var.aks_kubernetes_version
  automatic_upgrade_channel         = "stable"
  sku_tier                          = "Free"
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  role_based_access_control_enabled = true

  default_node_pool {
    name                = "default"
    node_count          = var.aks_enable_auto_scaling ? null : var.aks_node_count
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    zones               = ["1", "2", "3"]
    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_enable_auto_scaling ? var.aks_min_count : null
    max_count           = var.aks_enable_auto_scaling ? var.aks_max_count : null
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = var.aks_service_cidr
    dns_service_ip     = var.aks_dns_service_ip
    load_balancer_sku  = "standard"
  }

  tags = local.common_tags
}

# ============================================================================
# Federated Identity Credential for Workload Identity
# ============================================================================

resource "azurerm_federated_identity_credential" "aks" {
  name                = "${var.project_name}-fic-aks-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.aks.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:default:workload-identity-sa"
}

# ============================================================================
# Azure Container Registry
# ============================================================================

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = local.common_tags
}

# ============================================================================
# RBAC Role Assignment - ACR Pull
# ============================================================================

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# ============================================================================
# RBAC Role Assignment - Cosmos DB Data Contributor
# ============================================================================

resource "azurerm_cosmosdb_sql_role_assignment" "main" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.aks.principal_id
  scope               = azurerm_cosmosdb_account.main.id
}
