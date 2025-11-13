# GitHub Actions CI/CD Setup Guide

## Overview
This workflow automatically builds and pushes your Docker image to AWS ECR whenever you push code to the `main` branch.

## GitHub Secrets Configuration

You need to add the following secrets to your GitHub repository:

### How to Add Secrets:
1. Go to your GitHub repository: https://github.com/chiamaka99346/E-commerce-website
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret below

### Required Secrets:

| Secret Name | Description | How to Get It |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | Create IAM user with ECR permissions (see below) |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | From the same IAM user |

### Optional (Already in workflow as env vars):
- `AWS_REGION`: Already set to `eu-central-1` in workflow
- `ECR_REPOSITORY`: Already set to `ecommerce-app` in workflow

---

## Creating AWS IAM User for GitHub Actions

### Step 1: Create IAM User

Run these AWS CLI commands:

```bash
# Create IAM user
aws iam create-user --user-name github-actions-ecr

# Create access key
aws iam create-access-key --user-name github-actions-ecr
```

**Save the output!** It will show:
- `AccessKeyId` → Use this for `AWS_ACCESS_KEY_ID` secret
- `SecretAccessKey` → Use this for `AWS_SECRET_ACCESS_KEY` secret

### Step 2: Create IAM Policy

Save this as `ecr-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:eu-central-1:062266257890:repository/ecommerce-app"
    }
  ]
}
```

### Step 3: Attach Policy to User

```bash
# Create the policy
aws iam create-policy \
  --policy-name GitHubActionsECRPolicy \
  --policy-document file://ecr-policy.json

# Attach to user (replace ACCOUNT_ID with 062266257890)
aws iam attach-user-policy \
  --user-name github-actions-ecr \
  --policy-arn arn:aws:iam::062266257890:policy/GitHubActionsECRPolicy
```

---

## Workflow Triggers

The workflow runs when:
1. **Push to main branch** with changes to:
   - `app/**` (any app files)
   - `Dockerfile`
   - `nginx.conf`
   - Workflow file itself

2. **Manual trigger**: You can also run it manually from GitHub Actions UI

---

## What the Workflow Does

1. ✅ Checks out your code
2. ✅ Configures AWS credentials
3. ✅ Logs into Amazon ECR
4. ✅ Builds Docker image
5. ✅ Tags image with:
   - Git commit SHA (e.g., `abc123def456`)
   - `latest` tag
6. ✅ Pushes both tags to ECR
7. ✅ Displays image URI

---

## Testing the Workflow

### Option 1: Make a Small Change

```bash
# Make a small change to trigger the workflow
echo "<!-- Build timestamp: $(date) -->" >> app/index.html

# Commit and push
git add .
git commit -m "Test CI workflow"
git push origin main
```

### Option 2: Manual Trigger

1. Go to: https://github.com/chiamaka99346/E-commerce-website/actions
2. Click on "Build and Push to ECR"
3. Click "Run workflow" → Select `main` branch → "Run workflow"

---

## Viewing Workflow Results

1. Go to: https://github.com/chiamaka99346/E-commerce-website/actions
2. Click on the latest workflow run
3. Watch the progress in real-time
4. Check the logs for any errors

---

## Expected Output

When successful, you'll see:
```
✓ Image pushed to 062266257890.dkr.ecr.eu-central-1.amazonaws.com/ecommerce-app:abc123
✓ Image also tagged as latest
```

---

## Troubleshooting

### Error: "No such file or directory: app/"
- Make sure your app files are in the `app/` directory
- Check that you've pushed the folder structure to GitHub

### Error: "Access Denied"
- Verify AWS credentials are correct in GitHub Secrets
- Check IAM user has correct ECR permissions

### Error: "Repository does not exist"
- Ensure ECR repository was created by Terraform
- Verify repository name matches `ecommerce-app`

---

## Next Steps

After the workflow succeeds:
1. Verify image in ECR: `aws ecr describe-images --repository-name ecommerce-app`
2. Note the image URI for Kubernetes deployment
3. Continue to Phase 5 (Kubernetes manifests)
