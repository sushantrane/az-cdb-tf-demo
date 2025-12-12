#!/bin/bash
# ============================================================================
# Single-Region Cosmos DB Infrastructure Deployment Script
# ============================================================================
# This script automates the deployment of the single-region Cosmos DB
# infrastructure with AKS cluster
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions for colored output
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print banner
echo -e "${CYAN}============================================================================${NC}"
echo -e "${CYAN}  Single-Region Azure Cosmos DB Infrastructure Deployment${NC}"
echo -e "${CYAN}============================================================================${NC}"
echo ""

# Check prerequisites
print_info "Checking prerequisites..."

# Check Azure CLI
if command -v az &> /dev/null; then
    print_success "Azure CLI is installed"
else
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    print_success "Terraform is installed"
else
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check Azure login
print_info "Checking Azure login status..."
if az account show &> /dev/null; then
    ACCOUNT=$(az account show --query "{name:name, id:id, user:user.name}" -o json)
    USERNAME=$(echo $ACCOUNT | jq -r '.user')
    SUBNAME=$(echo $ACCOUNT | jq -r '.name')
    SUBID=$(echo $ACCOUNT | jq -r '.id')
    print_success "Logged in as $USERNAME"
    print_info "Using subscription: $SUBNAME ($SUBID)"
else
    print_warning "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Check for terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found."
    print_info "Copying terraform.tfvars.example to terraform.tfvars..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "Please edit terraform.tfvars with your values before continuing."
    echo ""
    echo -e "${YELLOW}Required changes:${NC}"
    echo -e "${YELLOW}  1. subscription_id - Your Azure subscription ID${NC}"
    echo -e "${YELLOW}  2. cosmosdb_account_name - Globally unique name${NC}"
    echo ""
    echo "Edit terraform.tfvars now and re-run this script."
    exit 0
fi

echo ""
echo -e "${CYAN}Deployment Options:${NC}"
echo "  1. Plan only (preview changes)"
echo "  2. Plan and Apply (deploy infrastructure)"
echo "  3. Destroy (remove all resources)"
echo ""

read -p "Select option (1-3): " choice

case $choice in
    1)
        print_info "Running Terraform plan..."
        terraform init
        terraform plan
        ;;
    2)
        print_info "Initializing Terraform..."
        terraform init
        
        print_info "Running Terraform plan..."
        terraform plan -out=tfplan
        
        echo ""
        read -p "Do you want to apply these changes? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            print_info "Deploying infrastructure..."
            if terraform apply tfplan; then
                print_success "Infrastructure deployed successfully!"
                echo ""
                print_info "Retrieving outputs..."
                terraform output
                
                echo ""
                print_success "Next steps:"
                echo "  1. Get AKS credentials:"
                KUBECONFIG_CMD=$(terraform output -raw kubeconfig_command)
                echo -e "     ${CYAN}$KUBECONFIG_CMD${NC}"
                echo ""
                echo "  2. Verify cluster access:"
                echo -e "     ${CYAN}kubectl get nodes${NC}"
                echo ""
                echo "  3. Use managed identity for workload:"
                CLIENT_ID=$(terraform output -raw managed_identity_client_id)
                echo -e "     ${CYAN}Client ID: $CLIENT_ID${NC}"
            else
                print_error "Deployment failed!"
                exit 1
            fi
        else
            print_info "Deployment cancelled."
        fi
        ;;
    3)
        print_warning "This will destroy all infrastructure resources!"
        echo ""
        read -p "Are you sure? Type 'destroy' to confirm: " confirm
        
        if [ "$confirm" = "destroy" ]; then
            print_info "Running Terraform destroy..."
            if terraform destroy; then
                print_success "Infrastructure destroyed successfully!"
            else
                print_error "Destroy failed!"
                exit 1
            fi
        else
            print_info "Destroy cancelled."
        fi
        ;;
    *)
        print_error "Invalid option selected."
        exit 1
        ;;
esac
