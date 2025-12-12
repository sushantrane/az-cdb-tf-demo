# ============================================================================
# Single-Region Cosmos DB Infrastructure Deployment Script (PowerShell)
# ============================================================================
# This script automates the deployment of the single-region Cosmos DB
# infrastructure with AKS cluster
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
Write-Host "  Single-Region Azure Cosmos DB Infrastructure Deployment" -ForegroundColor Cyan
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

# Check Azure login
Write-Info "Checking Azure login status..."
$account = az account show 2>$null | ConvertFrom-Json
if ($null -eq $account) {
    Write-Warning-Custom "Not logged in to Azure. Please run 'az login' first."
    exit 1
}
Write-Success "Logged in as $($account.user.name)"
Write-Info "Using subscription: $($account.name) ($($account.id))"

# Check for terraform.tfvars
if (-not (Test-Path "terraform.tfvars")) {
    Write-Warning-Custom "terraform.tfvars not found."
    Write-Info "Copying terraform.tfvars.example to terraform.tfvars..."
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Warning-Custom "Please edit terraform.tfvars with your values before continuing."
    Write-Host ""
    Write-Host "Required changes:" -ForegroundColor Yellow
    Write-Host "  1. subscription_id - Your Azure subscription ID" -ForegroundColor Yellow
    Write-Host "  2. cosmosdb_account_name - Globally unique name" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Press Enter to open terraform.tfvars for editing, or Ctrl+C to exit"
    Start-Process "terraform.tfvars"
    exit 0
}

Write-Host ""
Write-Host "Deployment Options:" -ForegroundColor Cyan
Write-Host "  1. Plan only (preview changes)" -ForegroundColor White
Write-Host "  2. Plan and Apply (deploy infrastructure)" -ForegroundColor White
Write-Host "  3. Destroy (remove all resources)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Select option (1-3)"

switch ($choice) {
    "1" {
        Write-Info "Running Terraform plan..."
        terraform init
        terraform plan
    }
    "2" {
        Write-Info "Initializing Terraform..."
        terraform init
        
        Write-Info "Running Terraform plan..."
        terraform plan -out=tfplan
        
        Write-Host ""
        $confirm = Read-Host "Do you want to apply these changes? (yes/no)"
        
        if ($confirm -eq "yes") {
            Write-Info "Deploying infrastructure..."
            terraform apply tfplan
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Infrastructure deployed successfully!"
                Write-Host ""
                Write-Info "Retrieving outputs..."
                terraform output
                
                Write-Host ""
                Write-Success "Next steps:"
                Write-Host "  1. Get AKS credentials:" -ForegroundColor White
                $kubeconfigCmd = terraform output -raw kubeconfig_command
                Write-Host "     $kubeconfigCmd" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  2. Verify cluster access:" -ForegroundColor White
                Write-Host "     kubectl get nodes" -ForegroundColor Gray
                Write-Host ""
                Write-Host "  3. Use managed identity for workload:" -ForegroundColor White
                $clientId = terraform output -raw managed_identity_client_id
                Write-Host "     Client ID: $clientId" -ForegroundColor Gray
            } else {
                Write-Error-Custom "Deployment failed!"
                exit 1
            }
        } else {
            Write-Info "Deployment cancelled."
        }
    }
    "3" {
        Write-Warning-Custom "This will destroy all infrastructure resources!"
        Write-Host ""
        $confirm = Read-Host "Are you sure? Type 'destroy' to confirm"
        
        if ($confirm -eq "destroy") {
            Write-Info "Running Terraform destroy..."
            terraform destroy
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Infrastructure destroyed successfully!"
            } else {
                Write-Error-Custom "Destroy failed!"
                exit 1
            }
        } else {
            Write-Info "Destroy cancelled."
        }
    }
    default {
        Write-Error-Custom "Invalid option selected."
        exit 1
    }
}
