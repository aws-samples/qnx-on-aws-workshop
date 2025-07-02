output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "private_key" {
  description = "Private key of the key pair"
  value       = tls_private_key.private_key.private_key_openssh
  sensitive   = true
}

output "private_key_secrets_manager_secret_id" {
  description = "Private Key secret id"
  value       = aws_secretsmanager_secret.private_key.id
}

output "ec2_instance_ubuntu_instance_id" {
  description = "EC2 Ubuntu instance id"
  value       = module.ec2_instance_ubuntu.id
}

output "ec2_instance_qnx_instance_id" {
  description = "QNX instance ID"
  value       = module.ec2_instance_qnx.id
}

output "ec2_instance_qnx_private_dns" {
  description = "QNX private DNS name"
  value       = module.ec2_instance_qnx.private_dns
}

output "ec2_instance_qnx_private_ip" {
  description = "QNX private IP address"
  value       = module.ec2_instance_qnx.private_ip
}

output "github_repository_url" {
  description = "GitHub repository URL"
  value       = "https://github.com/${var.github_user}/${var.github_repo}"
}

output "github_repository_name" {
  description = "GitHub repository name"
  value       = var.github_repo
}

output "github_user" {
  description = "GitHub username"
  value       = var.github_user
}

output "github_repo" {
  description = "GitHub repository name"
  value       = var.github_repo
}

# Infrastructure outputs for CI/CD
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.vpc.private_subnets[0]
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "key_pair_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.key_pair.key_name
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.kms_key.id
}

output "build_project_name" {
  description = "Build project name"
  value       = var.build_project_name
}

output "qnx_custom_ami_id" {
  description = "Custom QNX AMI ID"
  value       = var.qnx_custom_ami_id
}

output "terraform_version" {
  description = "Terraform version"
  value       = var.terraform_version
}

# CI/CD Configuration Outputs
output "ci_cd_provider" {
  description = "Selected CI/CD provider"
  value       = var.ci_cd_provider
}

output "ci_artifacts_bucket" {
  description = "S3 bucket for CI/CD artifacts and Terraform state"
  value       = var.ci_cd_provider != "none" ? aws_s3_bucket.ci_artifacts[0].bucket : null
}

# CodeBuild specific outputs
output "codebuild_project_name" {
  description = "CodeBuild project name (only when using CodeBuild)"
  value       = var.ci_cd_provider == "codebuild" ? aws_codebuild_project.workshop[0].name : null
}

output "codepipeline_name" {
  description = "CodePipeline name (only when using CodeBuild)"
  value       = var.ci_cd_provider == "codebuild" ? aws_codepipeline.codepipeline[0].name : null
}

output "github_connection_arn" {
  description = "GitHub connection ARN for CodePipeline (only when using CodeBuild)"
  value       = var.ci_cd_provider == "codebuild" ? aws_codestarconnections_connection.github[0].arn : null
}

# GitHub Actions specific outputs
output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN for OIDC authentication (only when using GitHub Actions)"
  value       = var.ci_cd_provider == "github-actions" ? aws_iam_role.github_actions[0].arn : null
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN (only when using GitHub Actions)"
  value       = var.ci_cd_provider == "github-actions" ? aws_iam_openid_connect_provider.github_actions[0].arn : null
}

output "github_actions_variables_created" {
  description = "List of GitHub Actions repository variables automatically created"
  value = var.ci_cd_provider == "github-actions" ? [
    "AWS_REGION",
    "AWS_ROLE_ARN", 
    "BUILD_PROJECT_NAME",
    "QNX_CUSTOM_AMI_ID",
    "VPC_ID",
    "PRIVATE_SUBNET_ID",
    "VPC_CIDR_BLOCK",
    "KEY_PAIR_NAME",
    "PRIVATE_KEY_SECRET_ID",
    "KMS_KEY_ID",
    "TF_VERSION",
    "TF_BACKEND_S3"
  ] : null
}

# Environment variables for CI/CD setup
output "ci_environment_variables" {
  description = "Environment variables needed for CI/CD setup"
  value = var.ci_cd_provider != "none" ? {
    AWS_REGION              = var.aws_region
    BUILD_PROJECT_NAME      = var.build_project_name
    QNX_CUSTOM_AMI_ID       = var.qnx_custom_ami_id
    VPC_ID                  = module.vpc.vpc_id
    PRIVATE_SUBNET_ID       = module.vpc.private_subnets[0]
    VPC_CIDR_BLOCK          = module.vpc.vpc_cidr_block
    KEY_PAIR_NAME           = aws_key_pair.key_pair.key_name
    PRIVATE_KEY_SECRET_ID   = aws_secretsmanager_secret.private_key.id
    KMS_KEY_ID              = aws_kms_key.kms_key.id
    TF_VERSION              = var.terraform_version
    TF_BACKEND_S3           = aws_s3_bucket.ci_artifacts[0].bucket
    # GitHub Actions specific
    AWS_ROLE_ARN            = var.ci_cd_provider == "github-actions" ? aws_iam_role.github_actions[0].arn : null
    # CodeBuild specific  
    GITHUB_CONNECTION_ARN   = var.ci_cd_provider == "codebuild" ? aws_codestarconnections_connection.github[0].arn : null
  } : null
}
