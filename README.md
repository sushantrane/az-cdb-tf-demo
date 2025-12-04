# Multi-Region Azure Cosmos DB Infrastructure

Terraform configuration for deploying a highly available, multi-region Azure Cosmos DB infrastructure with AKS clusters, private networking, and workload identity.

## Features

- **Multi-Region**: Active-active Cosmos DB across configurable Azure regions
- **Zone Redundancy**: Zone-redundant deployment in both regions
- **Private Networking**: Private endpoints, regional DNS zones, VNet peering
- **Security**: Azure AD authentication only, workload identity, no public access
- **High Availability**: Multi-region writes, continuous backup, TLS 1.2 minimum

## Architecture

Two-region deployment with:
- 2 AKS clusters (zone-redundant, Azure CNI, workload identity)
- 1 Cosmos DB account (SQL API, multi-region writes)
- 4 VNets (regional peering between AKS and Cosmos DB VNets)
- 2 Private endpoints with regional DNS zones
- Managed identities with RBAC for Cosmos DB access

## Quick Start

```bash
# Clone and navigate
git clone <repository-url>
cd az-cdb-tf-demo

# Authenticate to Azure
az login
az account set --subscription "<your-subscription-id>"

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

## Resources Deployed

- 2 Resource Groups (one per region)
- 4 Virtual Networks (AKS and Cosmos DB VNets per region)
- 4 VNet Peerings (regional only)
- 1 Cosmos DB Account (multi-region writes, SQL API)
- 2 Private Endpoints
- 2 Private DNS Zones (regional)
- 2 AKS Clusters (zone-redundant)
- 2 Managed Identities (workload identity)

## Configuration

All settings are configurable via `terraform.tfvars`:
- **Regions**: Primary and secondary Azure regions (default: eastus2, westus2)
- **Cosmos DB**: Autoscale throughput, consistency level, backup retention
- **AKS**: Node count, VM size, Kubernetes version
- **Networking**: CIDR ranges
- **Database**: Name, container, partition key

See `terraform.tfvars.example` for available options.

## Outputs

View deployment outputs:
```bash
terraform output                              # All outputs
terraform output cosmosdb_endpoint            # Cosmos DB endpoint
terraform output aks_primary_cluster_name     # Primary AKS cluster name
```

## Cleanup

```bash
terraform destroy
```

**Warning**: Permanently deletes all resources including Cosmos DB data.

## License

Provided as-is for demonstration purposes.

