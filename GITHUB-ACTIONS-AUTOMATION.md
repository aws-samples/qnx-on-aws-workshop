# GitHub Actions Automation Guide

This document explains the automated GitHub Actions setup that eliminates the need for manual repository variable configuration.

## Overview

When using `ci_cd_provider = "github-actions"`, Terraform automatically creates all required GitHub repository variables for you. This eliminates the manual step of setting up variables in the GitHub repository settings.

## How It Works

### 1. GitHub Provider Integration

The Terraform configuration includes the GitHub provider:

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token != "" ? var.github_token : null
  owner = var.github_user
}
```

### 2. Automatic Variable Creation

When `ci_cd_provider = "github-actions"`, Terraform creates the following repository variables:

- `AWS_REGION` - Your AWS region
- `AWS_ROLE_ARN` - GitHub Actions IAM role ARN for OIDC authentication
- `BUILD_PROJECT_NAME` - Your build project name
- `QNX_CUSTOM_AMI_ID` - Your custom QNX AMI ID
- `VPC_ID` - VPC ID from Terraform
- `PRIVATE_SUBNET_ID` - Private subnet ID
- `VPC_CIDR_BLOCK` - VPC CIDR block
- `KEY_PAIR_NAME` - EC2 key pair name
- `PRIVATE_KEY_SECRET_ID` - Secrets Manager secret ID
- `KMS_KEY_ID` - KMS key ID
- `TF_VERSION` - Terraform version
- `TF_BACKEND_S3` - S3 bucket for Terraform state

### 3. GitHub Token Authentication

To create repository variables, Terraform needs a GitHub personal access token with `repo` scope permissions.

## Setup Instructions

### Step 1: Create GitHub Personal Access Token

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a descriptive name (e.g., "QNX Workshop Terraform")
4. Select the **repo** scope (full control of private repositories)
5. Click **Generate token** and copy the token

### Step 2: Configure Authentication

**Option A: Environment Variable (Recommended)**
```bash
export GITHUB_TOKEN="your_github_personal_access_token_here"
```

**Option B: Terraform Variable**
```hcl
# In terraform.tfvars (less secure)
github_token = "your_github_personal_access_token_here"
```

### Step 3: Configure Terraform Variables

```hcl
# In terraform/terraform.tfvars
ci_cd_provider = "github-actions"
github_user = "your-github-username"
github_repo = "your-repository-name"
```

### Step 4: Deploy Infrastructure

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## Verification

After deployment, you can verify the variables were created:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions** → **Variables** tab
3. Confirm all 12 variables are present

You can also check the Terraform output:
```bash
terraform output github_actions_variables_created
```

## Security Considerations

### GitHub Token Security

- **Use environment variables**: Store the token in `GITHUB_TOKEN` environment variable rather than in terraform.tfvars
- **Limit scope**: Only grant `repo` scope permissions
- **Rotate regularly**: Consider rotating the token periodically
- **Secure storage**: Never commit tokens to version control

### Repository Variables

- Repository variables are visible to all repository collaborators
- Variables are automatically available to GitHub Actions workflows
- Variables are not encrypted (use secrets for sensitive data)

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```
   Error: GET https://api.github.com/repos/user/repo: 401 Bad credentials
   ```
   - Verify GITHUB_TOKEN is set correctly
   - Ensure token has `repo` scope permissions
   - Check that github_user and github_repo are correct

2. **Repository Not Found**
   ```
   Error: GET https://api.github.com/repos/user/repo: 404 Not Found
   ```
   - Verify repository exists and is accessible
   - Check github_user and github_repo values
   - Ensure token has access to the repository

3. **Permission Denied**
   ```
   Error: POST https://api.github.com/repos/user/repo/actions/variables: 403 Forbidden
   ```
   - Ensure token has `repo` scope permissions
   - Verify you have admin access to the repository

### Debugging Steps

1. **Verify GitHub Configuration**
   ```bash
   terraform output github_user
   terraform output github_repo
   ```

2. **Test GitHub API Access**
   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/YOUR_USER/YOUR_REPO
   ```

3. **Check Terraform State**
   ```bash
   terraform state list | grep github_actions_variable
   ```

## Manual Fallback

If you prefer not to use automated variable creation, you can:

1. Set `github_token = ""` in your configuration
2. Manually create the variables using the helper script:
   ```bash
   ./github-example-repo/verify-github-actions.sh
   ```

## Benefits

### For Users
- **Zero Manual Setup**: No need to manually create 12 repository variables
- **Error Prevention**: Eliminates typos and configuration mistakes
- **Consistency**: Ensures all variables are set correctly
- **Time Saving**: Reduces setup time significantly

### For Maintainers
- **Reduced Support**: Fewer setup-related issues
- **Better UX**: Smoother onboarding experience
- **Automation**: Infrastructure as Code principles applied to GitHub configuration

## Implementation Details

The automation is implemented in `terraform/ci-github-actions-automation.tf` using the GitHub Terraform provider. Each variable is created as a `github_actions_variable` resource with appropriate dependencies to ensure proper creation order.

Example resource:
```hcl
resource "github_actions_variable" "aws_region" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}
```

This ensures variables are only created when GitHub Actions is selected as the CI/CD provider.
