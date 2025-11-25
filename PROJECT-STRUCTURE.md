# Project Structure

```
az-cdb-tf-demo/
├── .gitignore                    # Git ignore patterns (excludes .tfvars, sample-app/, etc.)
├── README.md                     # Project documentation
├── terraform.tfvars.example      # Template for configuration values
├── providers.tf                  # Provider configuration
├── variables.tf                  # Variable definitions
├── main.tf                       # Core infrastructure resources
└── outputs.tf                    # Output values
```

## Core Files

### Infrastructure Code
- **main.tf** - All infrastructure resources (Cosmos DB, AKS, VNets, private endpoints, DNS zones)
- **variables.tf** - Input variable declarations with defaults
- **outputs.tf** - Output values (endpoints, resource IDs, connection info)
- **providers.tf** - Azure provider configuration and version constraints

### Configuration
- **terraform.tfvars.example** - Template showing required variables (commit to git)
- **terraform.tfvars** - Actual values with secrets (excluded from git)

### Documentation
- **README.md** - Setup guide, architecture overview, usage instructions
- **PROJECT-STRUCTURE.md** - This file

## Excluded from Git

The following are excluded via `.gitignore`:
- `terraform.tfvars` - Contains sensitive configuration
- `sample-app/` - Sample application code (not part of infrastructure)
- `.terraform/` - Provider plugins
- `*.tfstate*` - State files
- `tfplan` - Execution plans
- `deploy*.ps1`, `deploy*.sh` - Local deployment scripts
  - Cost estimation
  - Common commands and operations
- **PROJECT-STRUCTURE.md**: This file - project overview and structure

### Configuration Files

- **.gitignore**: Git ignore patterns for Terraform, IDE, and sensitive files

## Deployment Flow

1. **Prerequisites Check**: Verify Azure CLI, Terraform, and kubectl are installed
## Quick Start

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize values
2. Run `terraform init` to initialize providers
3. Run `terraform plan` to preview infrastructure
4. Run `terraform apply` to deploy

## Key Features

- Multi-region Azure Cosmos DB with private endpoints
- Zone-redundant AKS clusters in two regions
- Private networking with regional DNS zones
- Workload identity for secure authentication
- All configurable via Terraform variables
