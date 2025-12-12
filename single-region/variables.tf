# ============================================================================
# Terraform Variables Definition - Single Region
# ============================================================================

# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name prefix used for resource naming"
  type        = string
  default     = "az-cdb-poc"

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

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "az-cdb-poc"
    Environment = "dev"
  }
}

# ----------------------------------------------------------------------------
# Network Configuration
# ----------------------------------------------------------------------------

variable "vnet_aks_address_space" {
  description = "Address space for AKS VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vnet_cosmosdb_address_space" {
  description = "Address space for Cosmos DB VNet"
  type        = string
  default     = "10.2.0.0/16"
}

variable "subnet_aks_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_cosmosdb_address_prefix" {
  description = "Address prefix for Cosmos DB private endpoint subnet"
  type        = string
  default     = "10.2.1.0/24"
}

variable "aks_service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.100.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.100.0.10"
}

# ----------------------------------------------------------------------------
# Cosmos DB Configuration
# ----------------------------------------------------------------------------

variable "cosmosdb_account_name" {
  description = "Cosmos DB account name (must be globally unique, 3-44 characters, lowercase, alphanumeric and hyphens)"
  type        = string

  validation {
    condition     = length(var.cosmosdb_account_name) >= 3 && length(var.cosmosdb_account_name) <= 44 && can(regex("^[a-z0-9-]+$", var.cosmosdb_account_name))
    error_message = "Cosmos DB account name must be 3-44 characters, lowercase, alphanumeric and hyphens only."
  }
}

# ----------------------------------------------------------------------------
# Container Registry Configuration
# ----------------------------------------------------------------------------

variable "acr_name" {
  description = "Azure Container Registry name (must be globally unique, 5-50 characters, alphanumeric only)"
  type        = string

  validation {
    condition     = length(var.acr_name) >= 5 && length(var.acr_name) <= 50 && can(regex("^[a-zA-Z0-9]+$", var.acr_name))
    error_message = "ACR name must be 5-50 characters, alphanumeric only."
  }
}

variable "acr_sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be one of: Basic, Standard, Premium."
  }
}

# ----------------------------------------------------------------------------
# Cosmos DB Configuration (continued)
# ----------------------------------------------------------------------------

variable "cosmosdb_database_name" {
  description = "Name of the Cosmos DB SQL database"
  type        = string
  default     = "demo-db"
}

variable "cosmosdb_container_name" {
  description = "Name of the Cosmos DB container"
  type        = string
  default     = "items"
}

variable "cosmosdb_partition_key" {
  description = "Partition key path for the Cosmos DB container"
  type        = string
  default     = "/id"
}

variable "cosmosdb_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"

  validation {
    condition     = contains(["Eventual", "ConsistentPrefix", "Session", "BoundedStaleness", "Strong"], var.cosmosdb_consistency_level)
    error_message = "Consistency level must be one of: Eventual, ConsistentPrefix, Session, BoundedStaleness, Strong."
  }
}

variable "cosmosdb_autoscale_max_throughput" {
  description = "Maximum autoscale throughput for Cosmos DB (100-1000000 RU/s, in increments of 1000)"
  type        = number
  default     = 4000

  validation {
    condition     = var.cosmosdb_autoscale_max_throughput >= 1000 && var.cosmosdb_autoscale_max_throughput <= 1000000 && var.cosmosdb_autoscale_max_throughput % 1000 == 0
    error_message = "Autoscale max throughput must be between 1000-1000000 RU/s in increments of 1000."
  }
}

variable "cosmosdb_backup_interval_minutes" {
  description = "Interval in minutes between backups (60-1440)"
  type        = number
  default     = 240

  validation {
    condition     = var.cosmosdb_backup_interval_minutes >= 60 && var.cosmosdb_backup_interval_minutes <= 1440
    error_message = "Backup interval must be between 60-1440 minutes."
  }
}

variable "cosmosdb_backup_retention_hours" {
  description = "Backup retention in hours (8-720)"
  type        = number
  default     = 168

  validation {
    condition     = var.cosmosdb_backup_retention_hours >= 8 && var.cosmosdb_backup_retention_hours <= 720
    error_message = "Backup retention must be between 8-720 hours."
  }
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for Cosmos DB"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# AKS Configuration
# ----------------------------------------------------------------------------

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.33"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
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

variable "aks_enable_auto_scaling" {
  description = "Enable auto-scaling for AKS node pool"
  type        = bool
  default     = false
}

variable "aks_min_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 2
}

variable "aks_max_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}
