# Phase 8: Install Ingress Controller, cert-manager, and Configure DNS
# Simplified installation script

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phase 8: Ingress & Certificate Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check cluster connection
Write-Host "Checking cluster connection..." -ForegroundColor Yellow
$nodes = kubectl get nodes 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Not connected to Kubernetes cluster!" -ForegroundColor Red
    Write-Host "Run: aws eks update-kubeconfig --region eu-central-1 --name ecommerce-eks-cluster" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Connected to cluster" -ForegroundColor Green
Write-Host ""

# Get AWS account ID
$accountId = aws sts get-caller-identity --query Account --output text
Write-Host "AWS Account ID: $accountId" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install AWS Load Balancer Controller
Write-Host "[1/6] Installing AWS Load Balancer Controller..." -ForegroundColor Yellow
Write-Host "Downloading IAM policy..." -ForegroundColor Gray

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json" -OutFile "iam_policy.json"

Write-Host "Creating IAM policy..." -ForegroundColor Gray
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json 2>$null

Write-Host "Creating IAM service account..." -ForegroundColor Gray
eksctl create iamserviceaccount --cluster=ecommerce-eks-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::${accountId}:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=eu-central-1 --override-existing-serviceaccounts 2>$null

Write-Host "Installing controller with Helm..." -ForegroundColor Gray
helm repo add eks https://aws.github.io/eks-charts 2>$null
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=ecommerce-eks-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller 2>$null

Write-Host "✓ AWS Load Balancer Controller installed" -ForegroundColor Green
Write-Host ""

# Step 2: Install cert-manager
Write-Host "[2/6] Installing cert-manager..." -ForegroundColor Yellow
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
Write-Host "Waiting for cert-manager pods..." -ForegroundColor Gray
Start-Sleep -Seconds 30
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
Write-Host "✓ Cert-manager installed" -ForegroundColor Green
Write-Host ""

# Step 3: Configure ClusterIssuer
Write-Host "[3/6] Creating ClusterIssuer for Let's Encrypt..." -ForegroundColor Yellow
$email = Read-Host "Enter your email for Let's Encrypt notifications"
(Get-Content k8s/manifests/clusterissuer.yaml) -replace 'your-email@example.com', $email | Set-Content k8s/manifests/clusterissuer.yaml
kubectl apply -f k8s/manifests/clusterissuer.yaml
Write-Host "✓ ClusterIssuer created" -ForegroundColor Green
Write-Host ""

# Step 4: Deploy Ingress
Write-Host "[4/6] Deploying Ingress..." -ForegroundColor Yellow
kubectl apply -f k8s/manifests/ingress.yaml
Write-Host "✓ Ingress created" -ForegroundColor Green
Write-Host ""

# Step 5: Wait for Load Balancer
Write-Host "[5/6] Waiting for Load Balancer to be provisioned..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray
Start-Sleep -Seconds 30

$lbDns = ""
$attempts = 0
while ([string]::IsNullOrEmpty($lbDns) -and $attempts -lt 12) {
    Start-Sleep -Seconds 15
    $lbDns = kubectl get ingress ecommerce-ingress -n ecommerce -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    $attempts++
    Write-Host "." -NoNewline
}
Write-Host ""

if ([string]::IsNullOrEmpty($lbDns)) {
    Write-Host "⚠ Load Balancer DNS not ready yet" -ForegroundColor Yellow
    Write-Host "Check with: kubectl get ingress -n ecommerce" -ForegroundColor Gray
} else {
    Write-Host "✓ Load Balancer provisioned!" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Load Balancer DNS:" -ForegroundColor Yellow
    Write-Host "$lbDns" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
}
Write-Host ""

# Step 6: DNS Configuration Instructions
Write-Host "[6/6] DNS Configuration Required" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "CONFIGURE DNS ON NAMECHEAP" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Go to Namecheap.com and log in" -ForegroundColor White
Write-Host "2. Go to Domain List → Manage amakacloud.online" -ForegroundColor White
Write-Host "3. Go to Advanced DNS tab" -ForegroundColor White
Write-Host "4. Add these CNAME records:" -ForegroundColor White
Write-Host ""
Write-Host "   Record 1:" -ForegroundColor Cyan
Write-Host "   Type: CNAME" -ForegroundColor Gray
Write-Host "   Host: @" -ForegroundColor Gray
Write-Host "   Value: $lbDns" -ForegroundColor Yellow
Write-Host "   TTL: Automatic" -ForegroundColor Gray
Write-Host ""
Write-Host "   Record 2:" -ForegroundColor Cyan
Write-Host "   Type: CNAME" -ForegroundColor Gray
Write-Host "   Host: www" -ForegroundColor Gray
Write-Host "   Value: $lbDns" -ForegroundColor Yellow
Write-Host "   TTL: Automatic" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Save all changes and wait 5-10 minutes" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor certificate:" -ForegroundColor Yellow
Write-Host "kubectl get certificate -n ecommerce" -ForegroundColor Gray
Write-Host ""
Write-Host "Test your site (after DNS propagates):" -ForegroundColor Yellow
Write-Host "https://amakacloud.online" -ForegroundColor Cyan
Write-Host ""
