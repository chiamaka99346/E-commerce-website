# Terraform Infrastructure for E-commerce EKS Cluster

## Prerequisites

Before running Terraform, ensure you have:
- AWS CLI installed and configured with credentials
- Terraform >= 1.0 installed
- kubectl installed
- Appropriate AWS permissions to create VPC, EKS, ECR resources

## Infrastructure Components

This Terraform configuration creates:
- **VPC** with CIDR 10.0.0.0/16
- **2 Public subnets** (one per AZ)
- **2 Private subnets** (one per AZ)
- **Internet Gateway** for public subnet internet access
- **NAT Gateway** for private subnet internet access
- **EKS Cluster** (Kubernetes 1.28)
- **EKS Node Group** (2 t3.medium nodes)
- **ECR Repository** for container images

## Configuration

Default values are set in `variables.tf`. You can override them by:
1. Creating a `terraform.tfvars` file
2. Using `-var` flags
3. Setting environment variables

Key variables:
- `aws_region`: eu-central-1 (default)
- `cluster_name`: ecommerce-eks-cluster (default)
- `cluster_version`: 1.28 (default)
- `ecr_repository_name`: ecommerce-app (default)

## Deployment Steps

See the commands below in the main README.

## Outputs

After applying, Terraform will output:
- VPC and subnet IDs
- EKS cluster endpoint and name
- ECR repository URL
- Command to configure kubectl
