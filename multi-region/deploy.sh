#!/bin/bash
# ============================================================================
# Multi-Region Cosmos DB Infrastructure Deployment Script
# ============================================================================
# This script automates the deployment of the multi-region Cosmos DB
# infrastructure with AKS clusters
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print banner
echo "============================================================================"
echo "  Multi-Region Azure Cosmos DB Infrastructure Deployment"
echo "============================================================================"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

if ! command_exists az; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi
print_success "Azure CLI is installed"

if ! command_exists terraform; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi
print_success "Terraform is installed"

if ! command_exists kubectl; then
    print_warning "kubectl is not installed. You'll need it to interact with AKS clusters."
fi

# Check Azure login status
print_info "Checking Azure login status..."
if az account show &>/dev/null; then
    SUBSCRIPTION=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_success "Logged in to Azure subscription: $SUBSCRIPTION"
    echo "  Subscription ID: $SUBSCRIPTION_ID"
else
    print_error "Not logged in to Azure. Running 'az login'..."
    az login
fi

echo ""
read -p "$(echo -e ${YELLOW}Do you want to continue with this subscription? [y/N]:${NC} )" -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Exiting..."
    exit 0
fi

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init
print_success "Terraform initialized"

# Validate Terraform configuration
print_info "Validating Terraform configuration..."
terraform validate
print_success "Terraform configuration is valid"

# Format Terraform files
print_info "Formatting Terraform files..."
terraform fmt -recursive
print_success "Terraform files formatted"

# Generate and show plan
print_info "Generating Terraform plan..."
terraform plan -out=tfplan
print_success "Terraform plan generated"

echo ""
read -p "$(echo -e ${YELLOW}Do you want to apply this plan? [y/N]:${NC} )" -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Exiting without applying changes..."
    exit 0
fi

# Apply Terraform
print_info "Applying Terraform configuration..."
print_warning "This will take approximately 20-30 minutes..."
terraform apply tfplan
print_success "Infrastructure deployed successfully!"

# Get outputs
print_info "Retrieving deployment outputs..."
COSMOS_ENDPOINT=$(terraform output -raw cosmosdb_endpoint)
PRIMARY_CLUSTER=$(terraform output -raw aks_primary_cluster_name)
SECONDARY_CLUSTER=$(terraform output -raw aks_secondary_cluster_name)
PRIMARY_IDENTITY_CLIENT_ID=$(terraform output -raw aks_primary_managed_identity_client_id)
SECONDARY_IDENTITY_CLIENT_ID=$(terraform output -raw aks_secondary_managed_identity_client_id)
PRIMARY_RG=$(terraform output -raw primary_resource_group_name)
SECONDARY_RG=$(terraform output -raw secondary_resource_group_name)

echo ""
echo "============================================================================"
echo "  Deployment Summary"
echo "============================================================================"
echo ""
echo "Cosmos DB:"
echo "  Endpoint: $COSMOS_ENDPOINT"
echo ""
echo "Primary AKS Cluster (East US 2):"
echo "  Name: $PRIMARY_CLUSTER"
echo "  Resource Group: $PRIMARY_RG"
echo "  Managed Identity Client ID: $PRIMARY_IDENTITY_CLIENT_ID"
echo ""
echo "Secondary AKS Cluster (West US 2):"
echo "  Name: $SECONDARY_CLUSTER"
echo "  Resource Group: $SECONDARY_RG"
echo "  Managed Identity Client ID: $SECONDARY_IDENTITY_CLIENT_ID"
echo ""
echo "============================================================================"
echo "  Next Steps"
echo "============================================================================"
echo ""
echo "1. Get AKS credentials:"
echo "   Primary:   az aks get-credentials --resource-group $PRIMARY_RG --name $PRIMARY_CLUSTER"
echo "   Secondary: az aks get-credentials --resource-group $SECONDARY_RG --name $SECONDARY_CLUSTER"
echo ""
echo "2. Verify AKS clusters:"
echo "   kubectl get nodes"
echo ""
echo "3. Get managed identity client IDs for your applications:"
echo "   terraform output aks_primary_managed_identity_client_id"
echo "   terraform output aks_secondary_managed_identity_client_id"
echo ""
print_success "Deployment completed successfully!"
