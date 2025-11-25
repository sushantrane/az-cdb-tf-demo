# ============================================================================
# Terraform Provider Configuration
# ============================================================================
# This file configures the required Terraform providers and their versions
# for deploying multi-region Azure Cosmos DB infrastructure with AKS clusters
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Azure Resource Manager provider for managing Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    # Random provider for generating unique resource names
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Configure the Azure Resource Manager provider
provider "azurerm" {
  subscription_id = "d1eb41bc-1b7f-4404-bd2a-8568c222852d"
  
  features {
    # Resource group configuration
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    # Key Vault configuration for private endpoint scenarios
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
