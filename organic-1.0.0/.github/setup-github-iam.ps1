# Setup GitHub Actions IAM User
# Run this script to create an IAM user for GitHub Actions

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Actions IAM User Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$IAM_USER = "github-actions-ecr"
$POLICY_NAME = "GitHubActionsECRPolicy"
$ACCOUNT_ID = "062266257890"
$REGION = "eu-central-1"
$REPOSITORY = "ecommerce-app"

# Step 1: Create IAM User
Write-Host "[1/4] Creating IAM user: $IAM_USER..." -ForegroundColor Yellow

$userExists = aws iam get-user --user-name $IAM_USER 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ User already exists" -ForegroundColor Green
} else {
    aws iam create-user --user-name $IAM_USER
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ User created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create user" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 2: Create Access Key
Write-Host "[2/4] Creating access key..." -ForegroundColor Yellow

# Check if user already has access keys
$existingKeys = aws iam list-access-keys --user-name $IAM_USER --query 'AccessKeyMetadata[*].AccessKeyId' --output text
if ($existingKeys) {
    Write-Host "⚠ User already has access key(s): $existingKeys" -ForegroundColor Yellow
    $createNew = Read-Host "Create a new access key? (y/n)"
    if ($createNew -ne "y") {
        Write-Host "Skipping access key creation" -ForegroundColor Yellow
        Write-Host ""
    } else {
        $keyOutput = aws iam create-access-key --user-name $IAM_USER --output json | ConvertFrom-Json
        Write-Host "✓ Access key created!" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "SAVE THESE CREDENTIALS NOW!" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "AWS_ACCESS_KEY_ID: $($keyOutput.AccessKey.AccessKeyId)" -ForegroundColor Cyan
        Write-Host "AWS_SECRET_ACCESS_KEY: $($keyOutput.AccessKey.SecretAccessKey)" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Read-Host "Press Enter after you've saved these credentials"
    }
} else {
    $keyOutput = aws iam create-access-key --user-name $IAM_USER --output json | ConvertFrom-Json
    Write-Host "✓ Access key created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SAVE THESE CREDENTIALS NOW!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "AWS_ACCESS_KEY_ID: $($keyOutput.AccessKey.AccessKeyId)" -ForegroundColor Cyan
    Write-Host "AWS_SECRET_ACCESS_KEY: $($keyOutput.AccessKey.SecretAccessKey)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter after you've saved these credentials"
}

# Step 3: Create Policy
Write-Host "[3/4] Creating IAM policy..." -ForegroundColor Yellow

$policyArn = "arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
$policyExists = aws iam get-policy --policy-arn $policyArn 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Policy already exists" -ForegroundColor Green
} else {
    aws iam create-policy --policy-name $POLICY_NAME --policy-document file://.github/ecr-policy.json
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Policy created successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create policy" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Step 4: Attach Policy to User
Write-Host "[4/4] Attaching policy to user..." -ForegroundColor Yellow

$attachedPolicies = aws iam list-attached-user-policies --user-name $IAM_USER --query 'AttachedPolicies[*].PolicyArn' --output text
if ($attachedPolicies -like "*$POLICY_NAME*") {
    Write-Host "✓ Policy already attached" -ForegroundColor Green
} else {
    aws iam attach-user-policy --user-name $IAM_USER --policy-arn $policyArn
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Policy attached successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to attach policy" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/chiamaka99346/E-commerce-website/settings/secrets/actions" -ForegroundColor Gray
Write-Host "2. Add these secrets:" -ForegroundColor Gray
Write-Host "   - AWS_ACCESS_KEY_ID (from above)" -ForegroundColor Gray
Write-Host "   - AWS_SECRET_ACCESS_KEY (from above)" -ForegroundColor Gray
Write-Host "3. Push code to trigger the workflow" -ForegroundColor Gray
Write-Host ""
