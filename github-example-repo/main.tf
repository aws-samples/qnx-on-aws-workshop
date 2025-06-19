# ------------------------------------------------------------
# Terraform and provider versions
# ------------------------------------------------------------
terraform {
  required_version = ">= 1.9.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.1.0"
    }
  }

  backend "s3" {
    encrypt = true
    key     = "terraform.tfstate"
  }
}

# ------------------------------------------------------------
# Provider
# ------------------------------------------------------------
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}

# ------------------------------------------------------------
# Local values
# ------------------------------------------------------------
locals {
  # Computed values that depend on data sources
  account_id = data.aws_caller_identity.current.account_id
  
  # Parameters for EC2 QNX OS - using variables
  ec2_qnx = {
    ami                   = var.qnx_custom_ami_id
    instance_type         = var.qnx_instance_type
    instance_profile_name = var.qnx_instance_profile_name
  }
}

# ------------------------------------------------------------
# Data sources
# ------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "region" { state = "available" }

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

# Output configuration for EC2 instance for QNX OS
output "list_of_ec2_instance_qnx_private_dns" {
  description = "List of EC2 QNX private dns"
  value       = module.ec2_instance_qnx[*].private_dns
}
