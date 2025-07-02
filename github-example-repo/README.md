# CI/CD Setup Guide for QNX on AWS Workshop <!-- omit in toc -->

**English** | [日本語](README-ja.md)

This guide explains how to set up Continuous Integration/Continuous Deployment (CI/CD) for the QNX on AWS workshop using either AWS CodeBuild/CodePipeline or GitHub Actions.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [CI/CD Provider Selection](#cicd-provider-selection)
- [Option 1: GitHub Actions Setup (Default)](#option-1-github-actions-setup-default)
   - [1. Configure Terraform Variables](#1-configure-terraform-variables)
   - [2. Set up GitHub Authentication](#2-set-up-github-authentication)
   - [3. Deploy Infrastructure](#3-deploy-infrastructure)
   - [4. Automatic Repository Variables Setup ✨](#4-automatic-repository-variables-setup-)
   - [5. Copy Repository Files](#5-copy-repository-files)
   - [6. Monitor Workflow](#6-monitor-workflow)
- [Option 2: AWS CodeBuild/CodePipeline Setup](#option-2-aws-codebuildcodepipeline-setup)
   - [1. Configure Terraform Variables](#1-configure-terraform-variables-1)
   - [2. Deploy Infrastructure](#2-deploy-infrastructure)
   - [3. Configure GitHub Connection](#3-configure-github-connection)
   - [4. Copy Repository Files](#4-copy-repository-files)
   - [5. Monitor Pipeline](#5-monitor-pipeline)
- [Repository Structure](#repository-structure)
- [CI/CD Workflow](#cicd-workflow)
   - [Customizing the Workflow](#customizing-the-workflow)
      - [Modify Application Logic](#modify-application-logic)
      - [Adjust Instance Count](#adjust-instance-count)
      - [Change Application Arguments](#change-application-arguments)
- [Switching Between Providers](#switching-between-providers)
- [Comparison](#comparison)
- [Troubleshooting](#troubleshooting)
   - [Common Issues](#common-issues)
      - [CodeBuild Issues](#codebuild-issues)
      - [GitHub Actions Issues](#github-actions-issues)
   - [Debugging Steps](#debugging-steps)
   - [Security Considerations](#security-considerations)
      - [CodeBuild](#codebuild)
      - [GitHub Actions](#github-actions)
- [Next Steps](#next-steps)


## Overview

The workshop supports two CI/CD approaches:

1. **AWS CodeBuild/CodePipeline**: Fully managed AWS service with automatic GitHub integration
2. **GitHub Actions**: GitHub-native CI/CD with AWS OIDC authentication

Both approaches:
- Deploy temporary QNX EC2 instances for testing
- Execute your application on QNX targets
- Clean up resources automatically after completion
- Use the same Terraform infrastructure code

## Prerequisites

Before setting up CI/CD, ensure you have:

1. **Deployed the base workshop environment** using Terraform
2. **Created a custom QNX AMI** (see main workshop instructions)
3. **GitHub repository** with appropriate permissions
4. **AWS credentials** with administrative access

## CI/CD Provider Selection

The CI/CD provider is configured in your Terraform variables. Set `ci_cd_provider` in your `terraform.tfvars` file:

```hcl
# Choose your CI/CD provider
ci_cd_provider = "github-actions"   # Use GitHub Actions (default)
# ci_cd_provider = "codebuild"      # Use AWS CodeBuild/CodePipeline
```

## Option 1: GitHub Actions Setup (Default)

### 1. Configure Terraform Variables

In your `terraform/terraform.tfvars` file, set:

```hcl
# CI/CD Configuration
ci_cd_provider = "github-actions"

# GitHub Configuration
github_user = "your-github-username"
github_repo = "your-repository-name"
```

### 2. Set up GitHub Authentication

**Create a GitHub Personal Access Token:**

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a descriptive name (e.g., "QNX Workshop Terraform")
4. Select the **repo** scope (full control of private repositories)
5. Click **Generate token** and copy the token

**Set the token as an environment variable (recommended):**
```bash
export GITHUB_TOKEN="your_github_personal_access_token_here"
```

### 3. Deploy Infrastructure

```bash
cd terraform/
terraform plan
terraform apply --auto-approve
```

### 4. Automatic Repository Variables Setup ✨

**No manual setup required!** Terraform will automatically create all required GitHub repository variables:

- `AWS_REGION` - Your AWS region
- `AWS_ROLE_ARN` - IAM role ARN for OIDC authentication
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

You can verify the variables were created by checking: **Repository** → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

### 5. Copy Repository Files

```bash
# Get repository information from Terraform outputs
REPO_URL=$(terraform output -raw github_repository_url)
REPO_NAME=$(terraform output -raw github_repository_name)

# Clone your repository
cd ~
git clone ${REPO_URL}
cd ./${REPO_NAME}

# Copy workshop CI files (including .github directory)
cp -a <WORKSHOP_DIR>/github-example-repo/* ./
cp -a <WORKSHOP_DIR>/github-example-repo/.github ./

# Commit and push
git add -A
git commit -m "Add GitHub Actions CI/CD configuration"
git push origin main
```

### 6. Monitor Workflow

1. Go to your GitHub repository
2. Click **Actions** tab
3. Monitor the "QNX CI Pipeline" workflow execution

## Option 2: AWS CodeBuild/CodePipeline Setup

### 1. Configure Terraform Variables

In your `terraform/terraform.tfvars` file, set:

```hcl
# CI/CD Configuration
ci_cd_provider = "codebuild"

# GitHub Configuration
github_user = "your-github-username"
github_repo = "your-repository-name"
```

### 2. Deploy Infrastructure

```bash
cd terraform/
terraform plan
terraform apply --auto-approve
```

### 3. Configure GitHub Connection

After deployment, you need to manually configure the GitHub connection:

1. Go to **AWS Console** → **Developer Tools** → **Settings** → **Connections**
2. Find your connection (named after your `project_name`)
3. Click **Update pending connection**
4. Click **Install a new app** and follow GitHub authorization steps
5. Select your repository and complete the setup

### 4. Copy Repository Files

Copy the CI/CD files to your GitHub repository:

```bash
# Get repository information from Terraform outputs
REPO_URL=$(terraform output -raw github_repository_url)
REPO_NAME=$(terraform output -raw github_repository_name)

# Clone your repository
cd ~
git clone ${REPO_URL}
cd ./${REPO_NAME}

# Copy workshop CI files
cp -a <WORKSHOP_DIR>/github-example-repo/* ./

# Commit and push
git add -A
git commit -m "Add CI/CD configuration"
git push origin main
```

### 5. Monitor Pipeline

1. Go to **AWS Console** → **CodePipeline**
2. Find your pipeline (named after your `project_name`)
3. Monitor the execution progress

## Repository Structure

After copying the files, your repository should contain:

```
your-repo/
├── .github/
│   └── workflows/
│       └── qnx-ci.yml          # GitHub Actions workflow
├── app/
│   └── run_command.sh          # Sample application script
├── src/
│   └── get_primes.c           # Sample C application
├── buildspec.yaml             # CodeBuild specification
├── main.tf                    # Main Terraform configuration
├── ec2-qnx.tf                # QNX EC2 instance configuration
├── variables.tf              # Terraform variables
├── arguments.txt             # Application arguments
└── README-CI-SETUP.md        # This file
```

## CI/CD Workflow

Both CI/CD approaches follow the same workflow:

1. **Trigger**: Push to main branch or manual trigger
2. **Infrastructure**: Deploy temporary QNX EC2 instances using Terraform
3. **Application Deployment**: Copy application files to QNX instances
4. **Execution**: Run your application on each QNX instance
5. **Cleanup**: Destroy temporary infrastructure automatically

### Customizing the Workflow

#### Modify Application Logic

Edit `app/run_command.sh` to customize what runs on QNX instances:

```bash
#!/bin/bash
# Your custom application logic here
echo "Running on QNX with argument: $1"

# Example: Compile and run C application
gcc -o /tmp/get_primes /root/src/get_primes.c
/tmp/get_primes $1
```

#### Adjust Instance Count

Modify the `INSTANCE_COUNT` variable in:
- `buildspec.yaml` (for CodeBuild)
- `.github/workflows/qnx-ci.yml` (for GitHub Actions)

#### Change Application Arguments

Edit `arguments.txt` to provide different arguments to each instance:

```
1000
2000
3000
```

## Switching Between Providers

You can switch between GitHub Actions and CodeBuild by:

1. **Update Terraform Configuration**
   ```bash
   # Edit terraform.tfvars
   ci_cd_provider = "codebuild"        # or "github-actions" (default)
   ```

2. **Apply Changes**
   ```bash
   terraform plan
   terraform apply
   ```

3. **Update Repository Configuration**
   - For GitHub Actions: Set up repository variables (default)
   - For CodeBuild: Configure GitHub connection in AWS Console

## Comparison

| Feature | GitHub Actions | CodeBuild/CodePipeline |
|---------|----------------|------------------------|
| **Setup Complexity** | Low (OIDC authentication) | Medium (requires GitHub connection) |
| **Triggers** | Native GitHub triggers | GitHub webhooks via CodePipeline |
| **Configuration** | `.github/workflows/qnx-ci.yml` | `buildspec.yaml` |
| **Monitoring** | GitHub Actions UI | AWS Console (CodePipeline/CodeBuild) |
| **Cost** | GitHub Actions minutes | AWS CodeBuild pricing |
| **Integration** | Native GitHub integration | Deep AWS integration |
| **Secrets Management** | Repository variables | Environment variables |
| **VPC Support** | No (GitHub-hosted runners) | Yes (CodeBuild in VPC) |
| **Default Choice** | ✓ Recommended | Alternative |

## Troubleshooting

### Common Issues

#### CodeBuild Issues

1. **Connection not available**: Ensure GitHub connection is properly configured
2. **Permission denied**: Check CodeBuild IAM role permissions
3. **Terraform errors**: Verify all environment variables are set correctly

#### GitHub Actions Issues

1. **OIDC authentication failed**: Verify AWS_ROLE_ARN and repository settings
2. **Missing variables**: Ensure all required repository variables are configured
3. **Terraform backend errors**: Check S3 bucket permissions and configuration

### Debugging Steps

1. **Check Terraform outputs**:
   ```bash
   terraform output ci_environment_variables
   ```

2. **Verify AWS credentials**:
   ```bash
   aws sts get-caller-identity
   ```

3. **Check resource status**:
   ```bash
   # For CodeBuild
   aws codebuild list-projects
   aws codepipeline list-pipelines
   
   # For GitHub Actions
   # Check the Actions tab in your GitHub repository
   ```

### Security Considerations

#### CodeBuild
- Runs in your VPC with controlled network access
- Uses IAM roles for AWS service authentication
- Logs stored in CloudWatch with KMS encryption

#### GitHub Actions
- Uses OIDC for secure AWS authentication (no long-lived credentials)
- Runs on GitHub-hosted runners (outside your VPC)
- Repository variables visible to repository collaborators

Both options:
- Private keys stored securely in AWS Secrets Manager
- Temporary QNX instances created and destroyed per run
- S3 state bucket encrypted with KMS
- Least privilege IAM permissions

## Next Steps

After successful CI/CD setup:

1. Customize the application logic for your specific use case
2. Add more sophisticated testing scenarios
3. Integrate with your existing development workflow
4. Consider adding notifications for build status

For more advanced configurations and troubleshooting, refer to the main workshop documentation.
