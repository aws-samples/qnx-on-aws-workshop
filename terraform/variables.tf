# ------------------------------------------------------------
# Core Configuration Variables
# ------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "qnx-on-aws-ws-xx"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like 'us-east-1' or 'ap-northeast-1'."
  }
}

# ------------------------------------------------------------
# GitHub Configuration Variables
# ------------------------------------------------------------

variable "github_user" {
  description = "GitHub user name for CI/CD integration"
  type        = string

  validation {
    condition     = length(var.github_user) > 0
    error_message = "GitHub user name cannot be empty."
  }
}

variable "github_repo" {
  description = "GitHub repository name for CI/CD integration"
  type        = string
  default     = ""
}

# ------------------------------------------------------------
# EC2 QNX Configuration Variables
# ------------------------------------------------------------

variable "qnx_instance_type" {
  description = "EC2 instance type for QNX OS instances"
  type        = string
  default     = "c7g.xlarge"

  validation {
    condition = contains([
      "c7g.large", "c7g.xlarge", "c7g.2xlarge", "c7g.4xlarge", "c7g.8xlarge", "c7g.12xlarge", "c7g.16xlarge",
      "c8g.large", "c8g.xlarge", "c8g.2xlarge", "c8g.4xlarge", "c8g.8xlarge", "c8g.12xlarge", "c8g.16xlarge"
    ], var.qnx_instance_type)
    error_message = "QNX instance type must be a supported ARM-based instance type."
  }
}

variable "qnx_custom_ami_id" {
  description = "Custom AMI ID for QNX OS. If not provided, default QNX OS 8.0 AMI will be used"
  type        = string
  default     = ""
}

variable "qnx_instance_profile_name" {
  description = "IAM instance profile name for QNX EC2 instances"
  type        = string
  default     = "AmazonSSMRoleForInstancesQuickSetup"
}

# ------------------------------------------------------------
# EC2 Ubuntu Configuration Variables
# ------------------------------------------------------------

variable "ubuntu_instance_type" {
  description = "EC2 instance type for Ubuntu instances"
  type        = string
  default     = "t3.xlarge"

  validation {
    condition     = can(regex("^[a-z][1-9]+\\.[a-z]+$", var.ubuntu_instance_type))
    error_message = "Ubuntu instance type must be in the format like 't3.medium' or 'm5.large'."
  }
}

variable "ubuntu_root_volume_size" {
  description = "Root EBS volume size for Ubuntu instances (in GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.ubuntu_root_volume_size >= 8 && var.ubuntu_root_volume_size <= 1000
    error_message = "Ubuntu root volume size must be between 8 and 1000 GB."
  }
}

variable "ubuntu_instance_profile_name" {
  description = "IAM instance profile name for Ubuntu EC2 instances"
  type        = string
  default     = "AmazonSSMRoleForInstancesQuickSetup"
}

variable "ubuntu_user_password" {
  description = "Ubuntu user password"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = length(var.ubuntu_user_password) >= 8
    error_message = "Ubuntu user password must be at least 8 characters long."
  }
}

# ------------------------------------------------------------
# Network Configuration Variables
# ------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# ------------------------------------------------------------
# CI/CD Configuration Variables
# ------------------------------------------------------------

variable "ci_cd_provider" {
  description = "CI/CD provider to use: 'github-actions' for GitHub Actions or 'codebuild' for AWS CodeBuild/CodePipeline"
  type        = string
  default     = "github-actions"

  validation {
    condition     = contains(["codebuild", "github-actions"], var.ci_cd_provider)
    error_message = "CI/CD provider must be either 'codebuild' or 'github-actions'."
  }
}

variable "build_project_name" {
  description = "Name of the build project, used for resource naming and tagging"
  type        = string
  default     = "qnx-on-aws-ws-pl-xx"

  validation {
    condition     = length(var.build_project_name) > 0 && length(var.build_project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters."
  }
}

variable "terraform_version" {
  description = "Terraform version to use in CI/CD"
  type        = string
  default     = "1.9.3"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.terraform_version))
    error_message = "Terraform version must be in semantic version format (e.g., 1.9.3)."
  }
}

# Legacy variable for backward compatibility
variable "codebuild_terraform_version" {
  description = "Terraform version to use in CodeBuild (deprecated, use terraform_version instead)"
  type        = string
  default     = ""
}

