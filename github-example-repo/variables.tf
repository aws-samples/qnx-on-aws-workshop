# ------------------------------------------------------------
# Core Configuration Variables
# ------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging (for CI/CD pipeline)"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = ""
}

# ------------------------------------------------------------
# EC2 QNX Configuration Variables
# ------------------------------------------------------------

variable "qnx_custom_ami_id" {
  description = "Custom AMI ID for QNX OS. This should be your custom QNX AMI created in the workshop"
  type        = string
  default     = ""
}

variable "qnx_instance_type" {
  description = "EC2 instance type for QNX OS instances"
  type        = string
  default     = "c7g.xlarge"
}

variable "qnx_instance_profile_name" {
  description = "IAM instance profile name for QNX EC2 instances"
  type        = string
  default     = "AmazonSSMRoleForInstancesQuickSetup"
}


# ------------------------------------------------------------
# Infrastructure Variables (passed from CodeBuild)
# ------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID where resources will be created (passed from CodeBuild environment)"
  type        = string
  default     = ""
}

variable "private_subnet_id" {
  description = "Private subnet ID where EC2 instances will be launched (passed from CodeBuild environment)"
  type        = string
  default     = ""
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for security group rules (passed from CodeBuild environment)"
  type        = string
  default     = ""  
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access (passed from CodeBuild environment)"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS Key ID for encryption (passed from CodeBuild environment)"
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "Number of QNX instances to create in the CI/CD pipeline"
  type        = string
  default     = ""
}