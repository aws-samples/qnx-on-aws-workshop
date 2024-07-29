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

  # Parameters for EC2 QNX OS for Safety
  ec2_qnx_safety = {
    ami = "${local.ec2_qnx_safety_2_2_x_amis[local.region]}" # Default QNX OS for Safety 2.2.3 AMI
    # ami                   = "<YOUR_CUSTOM_AMI_ID>"  # Custom QNX OS for Safety AMI
    instance_type         = "m6g.medium"
    instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  }

  # Parameters for EC2 QNX Neutrino
  # Comment out the following code block in case you use QNX Neutrino.
  # ec2_qnx_neutrino = {
  #   ami = "${local.ec2_qnx_neutrino_7_1_amis[local.region]}" # Default QNX Neutrino RTOS 7.1 AMI
  #   # ami                   = "<YOUR_CUSTOM_AMI_ID>"  # Custom Neutrino RTOS AMI
  #   instance_type         = "m6g.medium"
  #   instance_profile_name = "AmazonSSMRoleForInstancesQuickSetup"
  # }

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

  # QNX OS for Safety 2.2.x AMI (https://aws.amazon.com/marketplace/pp/prodview-26pvihq76slfa)
  ec2_qnx_safety_2_2_x_amis = {
    ap-northeast-1 = "ami-09352f59561991aef"
    ap-northeast-2 = "ami-04330ff60902f1525"
    ap-northeast-3 = "ami-04b9463581c14e468"
    ap-southeast-1 = "ami-0afeb3ff59cab9116"
    eu-centeral-1  = "ami-006851ceb56ab3141"
    eu-west-1      = "ami-024a7cf21d6096a4b"
    us-east-1      = "ami-04ae083d500cf2201"
    us-west-2      = "ami-0f8b7081e08fbac0d"
  }

  # QNX Neutrino RTOS 7.1 AMI (https://aws.amazon.com/marketplace/pp/prodview-wjqoq2mq7hrhc)
  ec2_qnx_neutrino_7_1_amis = {
    ap-northeast-1 = "ami-07b27cce4ff4e52ec"
    ap-northeast-2 = "ami-0b7d0d03145f7c9f5"
    ap-northeast-3 = "ami-031d96cdfee759e61"
    ap-southeast-1 = "ami-0f8d843109d5a98fe"
    eu-centeral-1  = "ami-02018df98dd15096e"
    eu-west-1      = "ami-0b5fb49dadf512bf9"
    us-east-1      = "ami-02bd7b9e243f4d1bc"
    us-west-2      = "ami-0b6bcbf3a14628bdb"
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
