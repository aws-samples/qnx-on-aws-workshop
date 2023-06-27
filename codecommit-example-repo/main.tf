# ------------------------------------------------------------
# Terraform and provider versions
# ------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "= 4.0.4"
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

  # Parameters for EC2 QNX OS for Safety
  ec2_qnx_safety = {
    ami                   = "<YOUR_CUSTOM_AMI_ID>" # Custom QNX OS for Safety AMI
    instance_type         = "m6g.medium"
    instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  # Parameters for EC2 QNX Neutrino
  # Comment out the following code block in case you use QNX Neutrino.
  # ec2_qnx_neutrino = {
  #   ami                   = "<YOUR_CUSTOM_AMI_ID>" # QNX Neutrino custom RTOS 7.1 AMI
  #   instance_type         = "m6g.medium"
  #   instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  # }
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

# Output configuration for EC2 instance for QNX OS for Safety
output "list_of_ec2_instance_qnx_safety_private_dns" {
  description = "List of EC2 QNX Safety private dns"
  value       = module.ec2_instance_qnx_safety[*].private_dns
}

# Output configuration for EC2 instance for QNX Neutrino
# Comment out the following code block in case you use QNX Neutrino.

# output "list_of_ec2_instance_qnx_neutrino_private_dns" {
#   description = "List of EC2 QNX Neutrino purivate dns"
#   value       = module.ec2_instance_qnx_neutrino.private_dns
# }