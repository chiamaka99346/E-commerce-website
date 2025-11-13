# E-commerce App Docker Build and Push Script
# This script helps you build, test, and push the Docker image to ECR

# Exit on error
$ErrorActionPreference = "Stop"

# Configuration - REPLACE THESE WITH YOUR ACTUAL VALUES
$AWS_REGION = "eu-central-1"
$ECR_REPOSITORY_NAME = "ecommerce-app"
$AWS_ACCOUNT_ID = "062266257890"  # Replace with your 12-digit AWS account ID
$IMAGE_TAG = "latest"

# Derived values
$ECR_REPOSITORY_URL = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "E-commerce App - Docker Build & Push" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to build the image
function Build-Image {
    Write-Host "[1/5] Building Docker image..." -ForegroundColor Yellow
    docker build -t ecommerce-app:$IMAGE_TAG .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Docker build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Image built successfully" -ForegroundColor Green
    Write-Host ""
}

# Function to test the image locally
function Test-Image {
    Write-Host "[2/5] Testing image locally..." -ForegroundColor Yellow
    Write-Host "Starting container on port 8080..." -ForegroundColor Gray
    
    # Stop any existing container
    docker stop ecommerce-test 2>$null
    docker rm ecommerce-test 2>$null
    
    # Run the container
    docker run -d --name ecommerce-test -p 8080:80 ecommerce-app:$IMAGE_TAG
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to start container!" -ForegroundColor Red
        exit 1
    }
    
    Start-Sleep -Seconds 3
    
    Write-Host "✓ Container started successfully" -ForegroundColor Green
    Write-Host "→ Open http://localhost:8080 in your browser to test" -ForegroundColor Cyan
    Write-Host ""
    
    $response = Read-Host "Does the website look correct? (y/n)"
    
    # Stop test container
    docker stop ecommerce-test
    docker rm ecommerce-test
    
    if ($response -ne "y") {
        Write-Host "Build cancelled. Fix issues and try again." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# Function to authenticate with ECR
function Connect-ECR {
    Write-Host "[3/5] Authenticating with AWS ECR..." -ForegroundColor Yellow
    
    $ecrPassword = aws ecr get-login-password --region $AWS_REGION
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: AWS authentication failed!" -ForegroundColor Red
        Write-Host "Make sure AWS CLI is configured with valid credentials." -ForegroundColor Yellow
        exit 1
    }
    
    $ecrPassword | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Docker login to ECR failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Successfully authenticated with ECR" -ForegroundColor Green
    Write-Host ""
}

# Function to tag the image
function Tag-Image {
    Write-Host "[4/5] Tagging image for ECR..." -ForegroundColor Yellow
    docker tag ecommerce-app:$IMAGE_TAG "${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
    docker tag ecommerce-app:$IMAGE_TAG "${ECR_REPOSITORY_URL}:$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to tag image!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Image tagged successfully" -ForegroundColor Green
    Write-Host ""
}

# Function to push to ECR
function Push-Image {
    Write-Host "[5/5] Pushing image to ECR..." -ForegroundColor Yellow
    docker push "${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to push image to ECR!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ Image pushed successfully" -ForegroundColor Green
    Write-Host ""
}

# Main execution
try {
    Build-Image
    Test-Image
    Connect-ECR
    Tag-Image
    Push-Image
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS! Image pushed to ECR" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Image URL: ${ECR_REPOSITORY_URL}:${IMAGE_TAG}" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Update Kubernetes manifests with this image URL" -ForegroundColor Gray
    Write-Host "2. Deploy to EKS using kubectl or ArgoCD" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
