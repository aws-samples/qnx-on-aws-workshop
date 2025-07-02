#!/bin/bash

# GitHub Actions Setup Helper Script
# This script extracts the required environment variables from Terraform output
# and provides instructions for setting up GitHub Actions repository variables.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GitHub Actions Setup Helper ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "../terraform/terraform.tfvars" ]; then
    echo -e "${RED}Error: Please run this script from the github-example-repo directory${NC}"
    echo "Expected directory structure:"
    echo "  qnx-on-aws-workshop/"
    echo "  ├── terraform/"
    echo "  │   └── terraform.tfvars"
    echo "  └── github-example-repo/"
    echo "      └── setup-github-actions.sh (this script)"
    exit 1
fi

# Check if Terraform is deployed
cd ../terraform
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}Error: Terraform state not found. Please deploy the infrastructure first:${NC}"
    echo "  cd terraform/"
    echo "  terraform init"
    echo "  terraform apply"
    exit 1
fi

# Check if GitHub Actions is configured
CI_CD_PROVIDER=$(terraform output -raw ci_cd_provider 2>/dev/null || echo "")
if [ "$CI_CD_PROVIDER" != "github-actions" ]; then
    echo -e "${YELLOW}Warning: CI/CD provider is set to '$CI_CD_PROVIDER'${NC}"
    echo "To use GitHub Actions, set ci_cd_provider = \"github-actions\" in terraform.tfvars"
    echo "Then run: terraform apply"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}Extracting GitHub Actions variables from Terraform...${NC}"
echo ""

# Extract variables
AWS_REGION=$(terraform output -raw aws_region)
BUILD_PROJECT_NAME=$(terraform output -raw build_project_name 2>/dev/null || echo "")
QNX_CUSTOM_AMI_ID=$(terraform output -raw qnx_custom_ami_id 2>/dev/null || echo "")
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
PRIVATE_SUBNET_ID=$(terraform output -raw private_subnet_id 2>/dev/null || echo "")
VPC_CIDR_BLOCK=$(terraform output -raw vpc_cidr_block 2>/dev/null || echo "")
KEY_PAIR_NAME=$(terraform output -raw key_pair_name 2>/dev/null || echo "")
PRIVATE_KEY_SECRET_ID=$(terraform output -raw private_key_secrets_manager_secret_id 2>/dev/null || echo "")
KMS_KEY_ID=$(terraform output -raw kms_key_id 2>/dev/null || echo "")
TF_VERSION=$(terraform output -raw terraform_version 2>/dev/null || echo "1.9.3")
TF_BACKEND_S3=$(terraform output -raw ci_artifacts_bucket 2>/dev/null || echo "")
AWS_ROLE_ARN=$(terraform output -raw github_actions_role_arn 2>/dev/null || echo "")

# Get repository information
GITHUB_USER=$(terraform output -raw github_user 2>/dev/null || echo "")
GITHUB_REPO=$(terraform output -raw github_repo 2>/dev/null || echo "")

echo -e "${BLUE}Repository Information:${NC}"
echo "GitHub User: $GITHUB_USER"
echo "GitHub Repo: $GITHUB_REPO"
if [ -n "$GITHUB_USER" ] && [ -n "$GITHUB_REPO" ]; then
    echo "Repository URL: https://github.com/$GITHUB_USER/$GITHUB_REPO"
    echo "Variables URL: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings/variables/actions"
fi
echo ""

echo -e "${GREEN}GitHub Actions Repository Variables:${NC}"
echo "Copy and paste these values into your GitHub repository variables:"
echo ""
echo -e "${YELLOW}Go to: Settings → Secrets and variables → Actions → Variables tab${NC}"
echo ""

# Create a formatted table
printf "%-25s | %s\n" "Variable Name" "Value"
printf "%-25s-+--%s\n" "-------------------------" "----------------------------------------"
printf "%-25s | %s\n" "AWS_REGION" "$AWS_REGION"
printf "%-25s | %s\n" "AWS_ROLE_ARN" "$AWS_ROLE_ARN"
printf "%-25s | %s\n" "BUILD_PROJECT_NAME" "$BUILD_PROJECT_NAME"
printf "%-25s | %s\n" "QNX_CUSTOM_AMI_ID" "$QNX_CUSTOM_AMI_ID"
printf "%-25s | %s\n" "VPC_ID" "$VPC_ID"
printf "%-25s | %s\n" "PRIVATE_SUBNET_ID" "$PRIVATE_SUBNET_ID"
printf "%-25s | %s\n" "VPC_CIDR_BLOCK" "$VPC_CIDR_BLOCK"
printf "%-25s | %s\n" "KEY_PAIR_NAME" "$KEY_PAIR_NAME"
printf "%-25s | %s\n" "PRIVATE_KEY_SECRET_ID" "$PRIVATE_KEY_SECRET_ID"
printf "%-25s | %s\n" "KMS_KEY_ID" "$KMS_KEY_ID"
printf "%-25s | %s\n" "TF_VERSION" "$TF_VERSION"
printf "%-25s | %s\n" "TF_BACKEND_S3" "$TF_BACKEND_S3"

echo ""
echo -e "${BLUE}Alternative: JSON format for easy copying${NC}"
echo "{"
echo "  \"AWS_REGION\": \"$AWS_REGION\","
echo "  \"AWS_ROLE_ARN\": \"$AWS_ROLE_ARN\","
echo "  \"BUILD_PROJECT_NAME\": \"$BUILD_PROJECT_NAME\","
echo "  \"QNX_CUSTOM_AMI_ID\": \"$QNX_CUSTOM_AMI_ID\","
echo "  \"VPC_ID\": \"$VPC_ID\","
echo "  \"PRIVATE_SUBNET_ID\": \"$PRIVATE_SUBNET_ID\","
echo "  \"VPC_CIDR_BLOCK\": \"$VPC_CIDR_BLOCK\","
echo "  \"KEY_PAIR_NAME\": \"$KEY_PAIR_NAME\","
echo "  \"PRIVATE_KEY_SECRET_ID\": \"$PRIVATE_KEY_SECRET_ID\","
echo "  \"KMS_KEY_ID\": \"$KMS_KEY_ID\","
echo "  \"TF_VERSION\": \"$TF_VERSION\","
echo "  \"TF_BACKEND_S3\": \"$TF_BACKEND_S3\""
echo "}"

echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Go to your GitHub repository: https://github.com/$GITHUB_USER/$GITHUB_REPO"
echo "2. Navigate to Settings → Secrets and variables → Actions → Variables tab"
echo "3. Add each variable listed above"
echo "4. Copy the workshop files to your repository:"
echo "   git clone https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
echo "   cd $GITHUB_REPO"
echo "   cp -a ../github-example-repo/* ./"
echo "   cp -a ../github-example-repo/.github ./"
echo "   git add -A && git commit -m 'Add GitHub Actions CI/CD' && git push"
echo ""
echo -e "${YELLOW}Important: Make sure all variables are set before pushing to trigger the workflow!${NC}"

cd - > /dev/null
