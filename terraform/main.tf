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
  name       = "qnx-on-aws-ws-xx" # Replace `xx` with 2-digit ID
  region     = "ap-northeast-1"   # Specify your AWS region
  account_id = data.aws_caller_identity.current.account_id
  vpc = {
    cidr = "10.1.0.0/16" # VPC IPv4 CIDR
  }

  # Parameters for EC2 QNX OS
  ec2_qnx = {
    ami = "${local.ec2_qnx_8_0_amis[local.region]}" # Default QNX OS 8.0 AMI
    # ami                   = "<YOUR_CUSTOM_AMI_ID>"  # Custom QNX OS 8.0 AMI
    instance_type         = "c7g.xlarge"
    instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  # Parameters for EC2 Ubuntu instance
  ec2_ubuntu = {
    ami                   = data.aws_ami.ec2_ubuntu.id
    instance_type         = "t3.xlarge"
    instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
    ebs_root_volume_size  = "20"
  }

  # Parameters for CodeBuild
  codebuild = {
    tf_version = "1.9.3"
  }

  # QNX OS 8.0 AMI (https://aws.amazon.com/marketplace/pp/prodview-fyhziqwvrksrw)
  ec2_qnx_8_0_amis = {
    ap-northeast-1 = "ami-00b7185a20e55955a"
    ap-northeast-2 = "ami-0e887245900c58a3e"
    ap-southeast-1 = "ami-064f686d4fc7cc50c"
    eu-centeral-1  = "ami-09335f2437338bca2"
    eu-west-1      = "ami-0bf4f95decbd708f4"
    us-east-1      = "ami-01d86b0a4f2e53775"
    us-west-2      = "ami-0fc8f9aa5fba314be"
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
