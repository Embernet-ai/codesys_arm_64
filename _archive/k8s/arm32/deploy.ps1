# PowerShell deployment script for CODESYS ARM32 on k3s
# This script loads Docker images and deploys CODESYS to k3s

param(
    [Parameter(Mandatory=$false)]
    [string]$DockerImageFile = "codesys-arm32.tar",
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = "localhost:5000",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "codesys-arm32",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "CODESYS ARM32 Deployment to k3s" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Green

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kubectl not found" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: docker not found" -ForegroundColor Red
    exit 1
}

# Check if k3s is running
try {
    kubectl cluster-info | Out-Null
    Write-Host "Prerequisites OK" -ForegroundColor Green
} catch {
    Write-Host "Error: Cannot connect to Kubernetes cluster" -ForegroundColor Red
    exit 1
}

# Load Docker image
Write-Host "`nLoading Docker image from $DockerImageFile..." -ForegroundColor Green
if (-not (Test-Path $DockerImageFile)) {
    Write-Host "Error: Docker image file not found: $DockerImageFile" -ForegroundColor Red
    Write-Host "Please provide the path to your CODESYS ARM32 Docker image" -ForegroundColor Yellow
    Write-Host "Usage: .\deploy.ps1 -DockerImageFile <path-to-docker-image.tar>" -ForegroundColor Yellow
    exit 1
}

docker load -i $DockerImageFile

# Get the actual image name from the loaded image
$LoadedImage = (docker images --format "{{.Repository}}:{{.Tag}}" | Select-Object -First 1)
Write-Host "Loaded image: $LoadedImage" -ForegroundColor Green

# Tag image for local registry
Write-Host "`nTagging image for local registry..." -ForegroundColor Green
$RegistryImage = "$Registry/$ImageName`:$ImageTag"
docker tag $LoadedImage $RegistryImage

# Check if local registry is available
Write-Host "`nChecking for local registry..." -ForegroundColor Green
$registryAvailable = Test-NetConnection -ComputerName localhost -Port 5000 -InformationLevel Quiet -WarningAction SilentlyContinue

if ($registryAvailable) {
    Write-Host "Pushing to local registry..." -ForegroundColor Green
    docker push $RegistryImage
} else {
    Write-Host "Local registry not available. Image tagged locally." -ForegroundColor Yellow
    Write-Host "Note: You may need to import the image directly to k3s nodes" -ForegroundColor Yellow
}

# Create namespace
Write-Host "`nCreating namespace..." -ForegroundColor Green
kubectl apply -f ..\namespace.yaml

# Apply Kubernetes manifests
Write-Host "`nApplying Kubernetes manifests..." -ForegroundColor Green
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for deployment
Write-Host "`nWaiting for deployment to be ready..." -ForegroundColor Green
kubectl wait --for=condition=available --timeout=300s deployment/codesys-arm32 -n codesys

# Display status
Write-Host "`nDeployment Status:" -ForegroundColor Green
kubectl get all -n codesys -l arch=arm32

Write-Host "`nService Endpoints:" -ForegroundColor Green
kubectl get svc codesys-arm32 -n codesys

Write-Host "`n================================================" -ForegroundColor Green
Write-Host "CODESYS ARM32 deployment completed successfully!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To check logs:"
Write-Host "  kubectl logs -n codesys -l app=codesys,arch=arm32 -f"
Write-Host ""
Write-Host "To access the service:"
Write-Host "  kubectl port-forward -n codesys svc/codesys-arm32 1217:1217 8080:8080"
