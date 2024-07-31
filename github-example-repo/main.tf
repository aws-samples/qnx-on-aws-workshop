# ------------------------------------------------------------
# Terraform and provider versions
# ------------------------------------------------------------
terraform {
  required_version = ">= 1.9.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.60.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.0.5"
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
  region = local.region
  default_tags {
    tags = {
      Project = local.name
    }
  }
}

# ------------------------------------------------------------
# Local values
# ------------------------------------------------------------
locals {
  name       = "qnx-on-aws-ws-pl-xx" # Replace `xx` with 2-digit ID
  region     = "ap-northeast-1"      # Specify your AWS region
  account_id = data.aws_caller_identity.current.account_id

  # Parameters for EC2 QNX OS
  ec2_qnx = {
    ami                   = "<YOUR_CUSTOM_AMI_ID>" # Custom QNX OS AMI
    instance_type         = "c7g.xlarge"
    instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  }
}

# ------------------------------------------------------------
# Data sources
# ------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "region" { state = "available" }

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------
variable "vpc_id" {
  description = "vpc_id"
  type        = string
  default     = ""
}

variable "private_subnet_id" {
  description = "Private subnet ID"
  type        = string
  default     = ""
}

variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Key pair name"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS Key ID"
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "instance_count"
  type        = string
  default     = ""
}


# ------------------------------------------------------------
# Output
# ------------------------------------------------------------

# Output configuration for EC2 instance for QNX OS
output "list_of_ec2_instance_qnx_private_dns" {
  description = "List of EC2 QNX private dns"
  value       = module.ec2_instance_qnx[*].private_dns
}
