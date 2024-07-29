# ------------------------------------------------------------
# EC2 serial console acecss
# ------------------------------------------------------------
resource "aws_ec2_serial_console_access" "serial_console_access" {
  enabled = true
}

# ------------------------------------------------------------
# EC2 QNX instances
# ------------------------------------------------------------

# Resrouce configuration for EC2 instance for QNX OS for Safety
module "ec2_instance_qnx_safety" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "= 5.6.1"

  name = "${local.name}-qnx_safety"

  ami                    = local.ec2_qnx_safety["ami"]
  instance_type          = local.ec2_qnx_safety["instance_type"]
  vpc_security_group_ids = [aws_security_group.ec2_qnx.id]
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_qnx_instance_profile.name
  key_name               = aws_key_pair.key_pair.key_name
  root_block_device = [{
    encrypted = true
  }]
  metadata_options = {
    http_tokens = "required"
  }

  depends_on = [module.vpc.natgw_ids]
}

# Resrouce configuration for EC2 instance for QNX Neutrino
# Comment out the following code block in case you use QNX Neutrino.

# module "ec2_instance_qnx_neutrino" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "= 5.6.1"

#   name = "${local.name}-qnx_neutrino"

#   ami                    = local.ec2_qnx_neutrino["ami"]
#   instance_type          = local.ec2_qnx_neutrino["instance_type"]
#   vpc_security_group_ids = [aws_security_group.ec2_qnx.id]
#   subnet_id              = module.vpc.private_subnets[0]
#   iam_instance_profile   = aws_iam_instance_profile.ec2_qnx_instance_profile.name
#   key_name               = aws_key_pair.key_pair.key_name
#   root_block_device = [{
#     encrypted = true
#   }]
#   metadata_options = {
#     http_tokens = "required"
#   }

#   depends_on = [module.vpc.natgw_ids]
# }

# ------------------------------------------------------------
# Security group for EC2 QNX instance
# ------------------------------------------------------------
resource "aws_security_group" "ec2_qnx" {
  name_prefix = "${local.name}-ec2-"
  description = "EC2 SG for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_ubuntu.id]
  }
  ingress {
    description     = "QNX qconn"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_ubuntu.id]
  }

  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

# ------------------------------------------------------------
# IAM role for EC2 QNX instance
# ------------------------------------------------------------
resource "aws_iam_role" "ec2_qnx" {
  name_prefix = "${local.name}-ec2-qnx-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_qnx_instance_profile" {
  name_prefix = "${local.name}-instance-profile-"
  role        = aws_iam_role.ec2_qnx.name
}
