# ============================================================================
# Multi-Region Cosmos DB Infrastructure Deployment Script (PowerShell)
# ============================================================================
# This script automates the deployment of the multi-region Cosmos DB
# infrastructure with AKS clusters
# ============================================================================

# Stop on errors
$ErrorActionPreference = "Stop"

# Function to print colored messages
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Print banner
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Multi-Region Azure Cosmos DB Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Info "Checking prerequisites..."

# Check Azure CLI
try {
    $azVersion = az version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Azure CLI is installed"
    }
} catch {
    Write-Error-Custom "Azure CLI is not installed. Please install it first."
    exit 1
}

# Check Terraform
try {
    $tfVersion = terraform version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform is installed"
    }
} catch {
    Write-Error-Custom "Terraform is not installed. Please install it first."
    exit 1
}

# Check kubectl
try {
    $kubectlVersion = kubectl version --client 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "kubectl is installed"
    }
} catch {
    Write-Warning-Custom "kubectl is not installed. You'll need it to interact with AKS clusters."
}

# Check Azure login status
Write-Info "Checking Azure login status..."
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
        $subscriptionName = $account.name
        $subscriptionId = $account.id
        Write-Success "Logged in to Azure subscription: $subscriptionName"
        Write-Host "  Subscription ID: $subscriptionId" -ForegroundColor Gray
    }
} catch {
    Write-Error-Custom "Not logged in to Azure. Running 'az login'..."
    az login
}

Write-Host ""
$continue = Read-Host "Do you want to continue with this subscription? [y/N]"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Info "Exiting..."
    exit 0
}

# Initialize Terraform
Write-Info "Initializing Terraform..."
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform initialization failed"
    exit 1
}
Write-Success "Terraform initialized"

# Validate Terraform configuration
Write-Info "Validating Terraform configuration..."
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform validation failed"
    exit 1
}
Write-Success "Terraform configuration is valid"

# Format Terraform files
Write-Info "Formatting Terraform files..."
terraform fmt -recursive
Write-Success "Terraform files formatted"

# Generate and show plan
Write-Info "Generating Terraform plan..."
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform plan failed"
    exit 1
}
Write-Success "Terraform plan generated"

Write-Host ""
$apply = Read-Host "Do you want to apply this plan? [y/N]"
if ($apply -ne "y" -and $apply -ne "Y") {
    Write-Info "Exiting without applying changes..."
    exit 0
}

# Apply Terraform
Write-Info "Applying Terraform configuration..."
Write-Warning-Custom "This will take approximately 20-30 minutes..."
terraform apply tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Terraform apply failed"
    exit 1
}
Write-Success "Infrastructure deployed successfully!"

# Get outputs
Write-Info "Retrieving deployment outputs..."
$cosmosEndpoint = terraform output -raw cosmosdb_endpoint
$primaryCluster = terraform output -raw aks_primary_cluster_name
$secondaryCluster = terraform output -raw aks_secondary_cluster_name
$primaryIdentityClientId = terraform output -raw aks_primary_managed_identity_client_id
$secondaryIdentityClientId = terraform output -raw aks_secondary_managed_identity_client_id
$primaryRg = terraform output -raw primary_resource_group_name
$secondaryRg = terraform output -raw secondary_resource_group_name

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cosmos DB:" -ForegroundColor White
Write-Host "  Endpoint: $cosmosEndpoint" -ForegroundColor Gray
Write-Host ""
Write-Host "Primary AKS Cluster (East US 2):" -ForegroundColor White
Write-Host "  Name: $primaryCluster" -ForegroundColor Gray
Write-Host "  Resource Group: $primaryRg" -ForegroundColor Gray
Write-Host "  Managed Identity Client ID: $primaryIdentityClientId" -ForegroundColor Gray
Write-Host ""
Write-Host "Secondary AKS Cluster (West US 2):" -ForegroundColor White
Write-Host "  Name: $secondaryCluster" -ForegroundColor Gray
Write-Host "  Resource Group: $secondaryRg" -ForegroundColor Gray
Write-Host "  Managed Identity Client ID: $secondaryIdentityClientId" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Next Steps" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Get AKS credentials:" -ForegroundColor White
Write-Host "   Primary:   az aks get-credentials --resource-group $primaryRg --name $primaryCluster" -ForegroundColor Gray
Write-Host "   Secondary: az aks get-credentials --resource-group $secondaryRg --name $secondaryCluster" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Verify AKS clusters:" -ForegroundColor White
Write-Host "   kubectl get nodes" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Get managed identity client IDs for your applications:" -ForegroundColor White
Write-Host "   terraform output aks_primary_managed_identity_client_id" -ForegroundColor Gray
Write-Host "   terraform output aks_secondary_managed_identity_client_id" -ForegroundColor Gray
Write-Host ""
Write-Success "Deployment completed successfully!"
