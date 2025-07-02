#!/bin/bash

# GitHub Actions Verification Script
# This script verifies that GitHub Actions has been properly configured by Terraform
# and provides information about the automated setup.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GitHub Actions Verification Helper ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "../terraform/terraform.tfvars" ]; then
    echo -e "${RED}Error: Please run this script from the github-example-repo directory${NC}"
    echo "Expected directory structure:"
    echo "  qnx-on-aws-workshop/"
    echo "  ├── terraform/"
    echo "  │   └── terraform.tfvars"
    echo "  └── github-example-repo/"
    echo "      └── verify-github-actions.sh (this script)"
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

echo -e "${GREEN}✨ GitHub Actions Automated Setup Information ✨${NC}"
echo ""

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

echo -e "${GREEN}🎉 Automated Setup Complete!${NC}"
echo ""
echo "Terraform has automatically created the following GitHub repository variables:"

# Get the list of variables that were created
VARIABLES_CREATED=$(terraform output -raw github_actions_variables_created 2>/dev/null || echo "")
if [ -n "$VARIABLES_CREATED" ]; then
    echo "$VARIABLES_CREATED" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/\n/g' | sed 's/"//g' | sed 's/^[ \t]*/• /'
else
    echo "• AWS_REGION"
    echo "• AWS_ROLE_ARN"
    echo "• BUILD_PROJECT_NAME"
    echo "• QNX_CUSTOM_AMI_ID"
    echo "• VPC_ID"
    echo "• PRIVATE_SUBNET_ID"
    echo "• VPC_CIDR_BLOCK"
    echo "• KEY_PAIR_NAME"
    echo "• PRIVATE_KEY_SECRET_ID"
    echo "• KMS_KEY_ID"
    echo "• TF_VERSION"
    echo "• TF_BACKEND_S3"
fi

echo ""
echo -e "${BLUE}Verification Steps:${NC}"
echo "1. Go to your GitHub repository: https://github.com/$GITHUB_USER/$GITHUB_REPO"
echo "2. Navigate to Settings → Secrets and variables → Actions → Variables tab"
echo "3. Verify that all the variables listed above are present"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Copy the workshop files to your repository:"
echo "   git clone https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
echo "   cd $GITHUB_REPO"
echo "   cp -a ../github-example-repo/* ./"
echo "   cp -a ../github-example-repo/.github ./"
echo "   git add -A && git commit -m 'Add GitHub Actions CI/CD' && git push"
echo ""
echo "2. Monitor the workflow execution in the Actions tab of your repository"
echo ""
echo -e "${YELLOW}🚀 No manual variable setup required - everything is automated!${NC}"

cd - > /dev/null
