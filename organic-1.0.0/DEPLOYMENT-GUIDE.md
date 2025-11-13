# E-commerce Website Deployment - Complete Guide

## Overview
This project deploys a containerized e-commerce website to AWS EKS with full CI/CD automation using GitHub Actions and ArgoCD.

## Architecture
- **Frontend**: Static HTML/CSS/JS served by Nginx
- **Container Registry**: AWS ECR
- **Kubernetes**: AWS EKS (Managed Kubernetes)
- **CI**: GitHub Actions
- **CD**: ArgoCD (GitOps)
- **Ingress**: AWS Load Balancer Controller
- **TLS**: Let's Encrypt (automated via cert-manager)
- **DNS**: Namecheap (amakacloud.online)

## Prerequisites
- AWS CLI configured with credentials
- kubectl installed
- Terraform >= 1.0
- Docker Desktop (for local testing)
- eksctl (for EKS service account creation)
- Helm (for installing controllers)
- Domain registered on Namecheap

## Project Structure
```
.
├── app/                          # E-commerce frontend code
├── infra/terraform/              # Infrastructure as Code
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k8s/manifests/                # Kubernetes resources
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── clusterissuer.yaml
│   └── argocd-app.yaml
├── .github/workflows/            # CI/CD pipelines
│   └── ci-build-push.yml
├── Dockerfile                    # Container image definition
├── nginx.conf                    # Nginx configuration
└── install-phase7-8.ps1          # Automated setup script

```

## Deployment Steps

### Phase 1-5: Infrastructure & CI Setup ✅
1. Project structure created
2. Terraform code ready
3. Docker configuration complete
4. GitHub Actions CI pipeline configured
5. Kubernetes manifests created

### Phase 6: Install ArgoCD

After Terraform creates the EKS cluster, install ArgoCD:

```powershell
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD at: https://localhost:8080
- Username: `admin`
- Password: (from command above)

### Phase 7 & 8: Deploy Application and Configure Ingress

**Option 1: Automated Script (Recommended)**
```powershell
cd c:\Users\anumb\Downloads\Terraform-deployment\organic-1.0.0
.\install-phase7-8.ps1
```

**Option 2: Manual Steps**

1. **Deploy application:**
```powershell
kubectl apply -f k8s/manifests/namespace.yaml
kubectl apply -f k8s/manifests/deployment.yaml
kubectl apply -f k8s/manifests/service.yaml
```

2. **Install AWS Load Balancer Controller:**
```powershell
# Download IAM policy
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json" -OutFile "iam_policy.json"

# Create IAM policy
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=ecommerce-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::062266257890:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=eu-central-1

# Install with Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

3. **Install cert-manager:**
```powershell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
```

4. **Update email in ClusterIssuer:**
Edit `k8s/manifests/clusterissuer.yaml` and replace `your-email@example.com` with your email.

5. **Deploy ClusterIssuer and Ingress:**
```powershell
kubectl apply -f k8s/manifests/clusterissuer.yaml
kubectl apply -f k8s/manifests/ingress.yaml
```

6. **Get Load Balancer DNS:**
```powershell
kubectl get ingress ecommerce-ingress -n ecommerce
```

### Configure DNS on Namecheap

1. Log in to Namecheap
2. Go to Domain List → Manage `amakacloud.online`
3. Go to Advanced DNS tab
4. Add these CNAME records:

   **Record 1:**
   - Type: `CNAME`
   - Host: `@`
   - Value: `[YOUR-ALB-DNS-FROM-ABOVE].elb.eu-central-1.amazonaws.com`
   - TTL: Automatic

   **Record 2:**
   - Type: `CNAME`
   - Host: `www`
   - Value: `[YOUR-ALB-DNS-FROM-ABOVE].elb.eu-central-1.amazonaws.com`
   - TTL: Automatic

5. Save changes and wait 5-10 minutes for propagation

### Deploy ArgoCD Application

```powershell
kubectl apply -f k8s/manifests/argocd-app.yaml
```

This enables GitOps - ArgoCD will automatically sync your app from GitHub.

## Phase 9: End-to-End Testing

### 1. Verify Infrastructure
```powershell
# Check EKS cluster
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -n ecommerce
```

### 2. Verify ArgoCD
```powershell
# Check ArgoCD application status
kubectl get applications -n argocd

# Check application health
kubectl get application ecommerce-app -n argocd -o jsonpath='{.status.health.status}'
```

Should show: `Healthy`

### 3. Verify Certificate
```powershell
# Check certificate
kubectl get certificate -n ecommerce

# Check certificate details
kubectl describe certificate ecommerce-tls-secret -n ecommerce
```

Certificate should show `Ready: True`

### 4. Verify Ingress
```powershell
# Get ingress details
kubectl describe ingress ecommerce-ingress -n ecommerce
```

### 5. Test Website
Open your browser and visit:
- http://amakacloud.online (should redirect to HTTPS)
- https://amakacloud.online (should show your e-commerce site with valid SSL)
- https://www.amakacloud.online (should also work)

### 6. Test CI/CD Flow

Make a change to your website:
```powershell
# Edit a file
echo "<!-- Updated $(Get-Date) -->" >> app/index.html

# Commit and push
git add .
git commit -m "Test CI/CD flow"
git push origin main
```

**Expected behavior:**
1. GitHub Actions builds and pushes new image to ECR (2-3 min)
2. ArgoCD detects change and syncs (1-2 min)
3. New pods roll out automatically
4. Website updates with zero downtime

### 7. Check Logs
```powershell
# Application logs
kubectl logs -l app=ecommerce-app -n ecommerce --tail=50

# ArgoCD logs
kubectl logs -l app.kubernetes.io/name=argocd-server -n argocd --tail=50
```

## Monitoring & Maintenance

### View Application Status
```powershell
kubectl get all -n ecommerce
```

### Scale Application
```powershell
kubectl scale deployment ecommerce-app -n ecommerce --replicas=3
```

### View Ingress Status
```powershell
kubectl get ingress -n ecommerce -w
```

### Certificate Renewal
Certificates auto-renew 30 days before expiration. Check status:
```powershell
kubectl get certificaterequest -n ecommerce
```

## Troubleshooting

### Pods not starting
```powershell
kubectl describe pod -l app=ecommerce-app -n ecommerce
kubectl logs -l app=ecommerce-app -n ecommerce
```

### Certificate not issuing
```powershell
kubectl describe certificate ecommerce-tls-secret -n ecommerce
kubectl describe certificaterequest -n ecommerce
kubectl logs -l app=cert-manager -n cert-manager
```

### Ingress not working
```powershell
kubectl describe ingress ecommerce-ingress -n ecommerce
kubectl logs -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system
```

### DNS not resolving
```powershell
nslookup amakacloud.online
nslookup www.amakacloud.online
```

## Costs

Approximate monthly costs:
- EKS Cluster: $73
- EC2 instances (2 x t3.medium): $60
- NAT Gateway: $32
- Load Balancer: $16
- ECR storage: $1-5
- **Total**: ~$180-200/month

## Cleanup

To destroy all resources:
```powershell
cd infra/terraform
terraform destroy
```

Type `yes` when prompted. This will delete all AWS resources.

## Support

For issues or questions:
1. Check logs with kubectl commands above
2. Verify GitHub Actions workflow succeeded
3. Check ArgoCD UI for sync status
4. Ensure DNS is properly configured

## Next Steps

- Set up monitoring with Prometheus/Grafana
- Configure autoscaling (HPA/CA)
- Add staging environment
- Implement backup strategy
- Set up alerting
