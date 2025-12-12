# Single-Region Azure Cosmos DB Infrastructure

Terraform configuration for deploying a single-region Azure Cosmos DB infrastructure with AKS, private networking, and workload identity. Ideal for POC, development, and testing environments.

## Features

- **Zone Redundancy**: Zone-redundant Cosmos DB and AKS in one region
- **Private Networking**: Private endpoint, DNS zone, VNet peering
- **Security**: Azure AD authentication only, workload identity, no public access
- **Cost Optimized**: Single-region deployment for lower costs

## Architecture

Single-region deployment with:
- 1 AKS cluster (zone-redundant, Azure CNI, workload identity)
- 1 Cosmos DB account (SQL API, zone-redundant)
- 2 VNets (VNet peering between AKS and Cosmos DB VNets)
- 1 Private endpoint with DNS zone
- Managed identity with RBAC for Cosmos DB access

## Quick Start

```bash
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

Deployment takes approximately 15-20 minutes.

## Resources Deployed

- 1 Resource Group
- 2 Virtual Networks (AKS and Cosmos DB VNets)
- 2 Subnets
- 1 VNet Peering (bidirectional)
- 1 Cosmos DB Account (zone-redundant, SQL API)
- 1 Private Endpoint
- 1 Private DNS Zone
- 1 AKS Cluster (zone-redundant)
- 1 Managed Identity (workload identity)

## Configuration

All settings are configurable via `terraform.tfvars`:
- **Region**: Azure region (default: eastus2)
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
terraform output aks_cluster_name             # AKS cluster name
```

## Cleanup

```bash
terraform destroy
```

**Warning**: Permanently deletes all resources including Cosmos DB data.

## License

Provided as-is for demonstration purposes.
