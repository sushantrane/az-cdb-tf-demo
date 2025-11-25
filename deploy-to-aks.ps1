# ============================================================================
# Deploy Sample App to AKS - Quick Start Script
# ============================================================================

# Configuration - Update these values
$COSMOS_ENDPOINT = "https://az-cdb-tf-dev-01.documents.azure.com:443/"
$MANAGED_IDENTITY_CLIENT_ID = "eb3fbffc-5b36-4fd1-9b89-3b9dc02c941a"
$AKS_CLUSTER_NAME = "az-cdb-tf-dev-aks-eastus2"
$RESOURCE_GROUP = "az-cdb-tf-dev-rg-eastus2"
$ACR_NAME = "REPLACE_WITH_YOUR_ACR_NAME"  # e.g., "myregistry"
$IMAGE_NAME = "cosmosdb-sample-app"
$IMAGE_TAG = "latest"

Write-Host "=== Azure Cosmos DB Sample App Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get AKS credentials
Write-Host "Step 1: Getting AKS credentials..." -ForegroundColor Yellow
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to get AKS credentials"; exit 1 }

# Step 2: Build and push Docker image (choose one option)
Write-Host ""
Write-Host "Step 2: Build and push Docker image..." -ForegroundColor Yellow
Write-Host "Option A: Using Azure Container Registry (ACR)" -ForegroundColor Green
Write-Host "  Command: az acr build --registry $ACR_NAME --image ${IMAGE_NAME}:${IMAGE_TAG} ./sample-app"
Write-Host ""
Write-Host "Option B: Using Docker Hub" -ForegroundColor Green
Write-Host "  Commands:"
Write-Host "    docker build -t yourusername/${IMAGE_NAME}:${IMAGE_TAG} ./sample-app"
Write-Host "    docker push yourusername/${IMAGE_NAME}:${IMAGE_TAG}"
Write-Host ""
$choice = Read-Host "Choose option (A for ACR, B for Docker Hub, S to skip if already pushed)"

if ($choice -eq "A") {
    if ($ACR_NAME -eq "REPLACE_WITH_YOUR_ACR_NAME") {
        $ACR_NAME = Read-Host "Enter your ACR name (without .azurecr.io)"
    }
    Write-Host "Building and pushing to ACR..." -ForegroundColor Green
    az acr build --registry $ACR_NAME --image "${IMAGE_NAME}:${IMAGE_TAG}" ./sample-app
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to build/push image"; exit 1 }
    $IMAGE_FULL = "${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Attach ACR to AKS if needed
    Write-Host "Attaching ACR to AKS..." -ForegroundColor Green
    az aks update --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP --attach-acr $ACR_NAME
} elseif ($choice -eq "B") {
    $dockerUsername = Read-Host "Enter your Docker Hub username"
    Write-Host "Building and pushing to Docker Hub..." -ForegroundColor Green
    docker build -t "${dockerUsername}/${IMAGE_NAME}:${IMAGE_TAG}" ./sample-app
    docker push "${dockerUsername}/${IMAGE_NAME}:${IMAGE_TAG}"
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to build/push image"; exit 1 }
    $IMAGE_FULL = "${dockerUsername}/${IMAGE_NAME}:${IMAGE_TAG}"
} else {
    $IMAGE_FULL = Read-Host "Enter full image name (e.g., myregistry.azurecr.io/cosmosdb-sample-app:latest)"
}

# Step 3: Update Kubernetes manifests
Write-Host ""
Write-Host "Step 3: Updating Kubernetes manifests..." -ForegroundColor Yellow

# Update serviceaccount.yaml
$serviceAccountContent = Get-Content ./sample-app/k8s/serviceaccount.yaml -Raw
$serviceAccountContent = $serviceAccountContent -replace 'REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID', $MANAGED_IDENTITY_CLIENT_ID
Set-Content ./sample-app/k8s/serviceaccount.yaml -Value $serviceAccountContent

# Update deployment.yaml
$deploymentContent = Get-Content ./sample-app/k8s/deployment.yaml -Raw
$deploymentContent = $deploymentContent -replace 'REPLACE_WITH_YOUR_ACR_NAME\.azurecr\.io/cosmosdb-sample-app:latest', $IMAGE_FULL
$deploymentContent = $deploymentContent -replace 'REPLACE_WITH_COSMOS_ENDPOINT', $COSMOS_ENDPOINT
$deploymentContent = $deploymentContent -replace 'REPLACE_WITH_MANAGED_IDENTITY_CLIENT_ID', $MANAGED_IDENTITY_CLIENT_ID
Set-Content ./sample-app/k8s/deployment.yaml -Value $deploymentContent

Write-Host "Manifests updated!" -ForegroundColor Green

# Step 4: Deploy to AKS
Write-Host ""
Write-Host "Step 4: Deploying to AKS..." -ForegroundColor Yellow
kubectl apply -f ./sample-app/k8s/serviceaccount.yaml
kubectl apply -f ./sample-app/k8s/deployment.yaml

# Step 5: Check deployment status
Write-Host ""
Write-Host "Step 5: Checking deployment status..." -ForegroundColor Yellow
Write-Host "Waiting for pods to be ready..." -ForegroundColor Green
kubectl wait --for=condition=ready pod -l app=cosmosdb-sample-app --timeout=180s

# Step 6: Get service endpoint
Write-Host ""
Write-Host "Step 6: Getting service endpoint..." -ForegroundColor Yellow
Write-Host "Waiting for LoadBalancer IP (this may take 2-3 minutes)..." -ForegroundColor Green
kubectl get svc cosmosdb-sample-app -w --timeout=180s

Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To get the external IP:" -ForegroundColor Yellow
Write-Host "  kubectl get svc cosmosdb-sample-app"
Write-Host ""
Write-Host "To test the app:" -ForegroundColor Yellow
Write-Host '  $EXTERNAL_IP = (kubectl get svc cosmosdb-sample-app -o jsonpath="{.status.loadBalancer.ingress[0].ip}")'
Write-Host '  curl.exe http://$EXTERNAL_IP/health'
Write-Host '  curl.exe -X POST http://$EXTERNAL_IP/test'
Write-Host ""
Write-Host "To check logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -l app=cosmosdb-sample-app --tail=50 -f"
