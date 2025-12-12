# Azure Cosmos DB Infrastructure with Terraform

Terraform configurations for deploying Azure Cosmos DB infrastructure with AKS, private networking, and workload identity.

## Available Configurations

### [Multi-Region](./multi-region/)
Production-ready multi-region deployment with:
- Active-active Cosmos DB across two configurable Azure regions
- Zone-redundant AKS clusters in both regions
- Regional private endpoints and DNS zones
- Multi-region writes for high availability

**Use case**: Production workloads requiring high availability, disaster recovery, and global distribution.

### [Single-Region](./single-region/)
Simplified single-region deployment for POC/development:
- Single Cosmos DB account with availability zones
- Zone-redundant AKS cluster in one region
- Private endpoint and DNS zone
- Lower cost for testing and development

**Use case**: Development, testing, POC, or cost-sensitive workloads in a single region.

## Quick Start

Navigate to the desired configuration folder and follow the README instructions:

```bash
# For multi-region deployment
cd multi-region

# For single-region deployment  
cd single-region
```

## Prerequisites

- Azure CLI
- Terraform >= 1.5.0
- Azure subscription with appropriate permissions

## License

Provided as-is for demonstration purposes.

