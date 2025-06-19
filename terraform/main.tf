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
  # Computed values that depend on data sources or complex logic
  account_id = data.aws_caller_identity.current.account_id

  # Parameters for EC2 QNX OS - using variables with fallback to default AMIs
  ec2_qnx = {
    ami                   = var.qnx_custom_ami_id != "" ? var.qnx_custom_ami_id : local.ec2_qnx_8_0_amis[var.aws_region]
    instance_type         = var.qnx_instance_type
    instance_profile_name = var.qnx_instance_profile_name
  }

  # Parameters for EC2 Ubuntu instance
  ec2_ubuntu = {
    ami                   = data.aws_ami.ec2_ubuntu.id
    instance_type         = var.ubuntu_instance_type
    instance_profile_name = var.ubuntu_instance_profile_name
    ebs_root_volume_size  = var.ubuntu_root_volume_size
  }

  # QNX OS 8.0.2 AMI mapping
  # (https://aws.amazon.com/marketplace/pp/prodview-fyhziqwvrksrw)
  ec2_qnx_8_0_amis = {
    ap-northeast-1 = "ami-00d87a0d18aed9c04"
    ap-northeast-2 = "ami-0552ae8b891aad54a"
    ap-southeast-1 = "ami-03909bede4707f162"
    eu-centeral-1  = "ami-0aba071c35966df3a"
    eu-west-1      = "ami-09fc3726b8fdb44aa"
    us-east-1      = "ami-0d07d4120bfb8ef3d"
    us-west-2      = "ami-0095b80a82406356a"
  }
}

# ------------------------------------------------------------
# Data sources
# ------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "region" { state = "available" }

# Ubuntu Server 22.04 LTS AMI
data "aws_ami" "ec2_ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}
