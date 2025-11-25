# ============================================================================
# Terraform Variables Definition
# ============================================================================
# This file defines all input variables for the multi-region Cosmos DB
# infrastructure deployment with comprehensive validation and descriptions
# ============================================================================

# ----------------------------------------------------------------------------
# Project Configuration Variables
# ----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name prefix used for resource naming convention"
  type        = string
  default     = "az-cdb-tf"

  validation {
    condition     = length(var.project_name) <= 12 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 12 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location_primary" {
  description = "Primary Azure region for deployment"
  type        = string
  default     = "eastus2"
}

variable "location_secondary" {
  description = "Secondary Azure region for deployment"
  type        = string
  default     = "westus2"
}

# ----------------------------------------------------------------------------
# Network Configuration Variables
# ----------------------------------------------------------------------------

variable "vnet_address_spaces" {
  description = "Address spaces for VNets in each region"
  type = object({
    primary_aks      = string
    primary_cosmosdb = string
    secondary_aks    = string
    secondary_cosmosdb = string
  })
  default = {
    primary_aks        = "10.1.0.0/16"
    primary_cosmosdb   = "10.2.0.0/16"
    secondary_aks      = "10.11.0.0/16"
    secondary_cosmosdb = "10.12.0.0/16"
  }
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes for AKS and Cosmos DB"
  type = object({
    primary_aks_subnet      = string
    primary_cosmosdb_subnet = string
    secondary_aks_subnet    = string
    secondary_cosmosdb_subnet = string
  })
  default = {
    primary_aks_subnet        = "10.1.1.0/24"
    primary_cosmosdb_subnet   = "10.1.2.0/24"
    secondary_aks_subnet      = "10.11.1.0/24"
    secondary_cosmosdb_subnet = "10.11.2.0/24"
  }
}

variable "aks_service_cidrs" {
  description = "Service CIDR blocks for AKS clusters"
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "10.100.0.0/16"
    secondary = "10.200.0.0/16"
  }
}

variable "aks_dns_service_ips" {
  description = "DNS service IPs for AKS clusters"
  type = object({
    primary   = string
    secondary = string
  })
  default = {
    primary   = "10.100.0.10"
    secondary = "10.200.0.10"
  }
}

# ----------------------------------------------------------------------------
# Cosmos DB Configuration Variables
# ----------------------------------------------------------------------------

variable "cosmosdb_account_name" {
  description = "Cosmos DB account name (must be globally unique)"
  type        = string
  default     = "az-cdb-tf-dev-01"

  validation {
    condition     = length(var.cosmosdb_account_name) >= 3 && length(var.cosmosdb_account_name) <= 44
    error_message = "Cosmos DB account name must be between 3 and 44 characters."
  }
}

variable "cosmosdb_database_name" {
  description = "Cosmos DB SQL database name"
  type        = string
  default     = "demo-db"
}

variable "cosmosdb_container_name" {
  description = "Cosmos DB container name"
  type        = string
  default     = "threads"
}

variable "cosmosdb_partition_key" {
  description = "Partition key path for Cosmos DB container"
  type        = string
  default     = "/user_id"
}

variable "cosmosdb_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Eventual"

  validation {
    condition = contains([
      "Eventual",
      "ConsistentPrefix",
      "Session",
      "BoundedStaleness",
      "Strong"
    ], var.cosmosdb_consistency_level)
    error_message = "Invalid consistency level."
  }
}

variable "cosmosdb_autoscale_max_throughput" {
  description = "Maximum autoscale throughput for Cosmos DB (RU/s)"
  type        = number
  default     = 10000

  validation {
    condition     = var.cosmosdb_autoscale_max_throughput >= 1000 && var.cosmosdb_autoscale_max_throughput <= 1000000
    error_message = "Autoscale max throughput must be between 1000 and 1000000 RU/s."
  }
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for Cosmos DB (99.995% SLA)"
  type        = bool
  default     = true
}

variable "enable_multi_region_writes" {
  description = "Enable multi-region writes for Cosmos DB (active-active)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access to Cosmos DB"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# AKS Configuration Variables
# ----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for AKS clusters"
  type        = string
  default     = "1.33"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS default node pool"
  type        = number
  default     = 2

  validation {
    condition     = var.aks_node_count >= 1 && var.aks_node_count <= 100
    error_message = "Node count must be between 1 and 100."
  }
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.aks_network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "aks_network_policy" {
  description = "Network policy for AKS"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico"], var.aks_network_policy)
    error_message = "Network policy must be either 'azure' or 'calico'."
  }
}

variable "enable_workload_identity" {
  description = "Enable workload identity for AKS clusters"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Kubernetes Workload Configuration
# ----------------------------------------------------------------------------

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name for workload identity"
  type        = string
  default     = "cosmosdb-workload-sa"
}

# ----------------------------------------------------------------------------
# Tagging Configuration
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "az-cdb-tf"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Purpose     = "Multi-Region CosmosDB HA Demo"
  }
}
