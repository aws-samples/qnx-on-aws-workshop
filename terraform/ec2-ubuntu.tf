# ------------------------------------------------------------
# EC2 Ubuntu instance
# ------------------------------------------------------------
module "ec2_instance_ubuntu" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "= 5.1.0"

  name = "${local.name}-ubuntu"

  ami                    = local.ec2_ubuntu["ami"]
  instance_type          = local.ec2_ubuntu["instance_type"]
  vpc_security_group_ids = [aws_security_group.ec2_ubuntu.id]
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ubuntu_instance_profile.name
  key_name               = aws_key_pair.key_pair.key_name
  root_block_device = [{
    encrypted   = true,
    volume_size = local.ec2_ubuntu["ebs_root_volume_size"]
  }]
  metadata_options = {
    http_tokens = "required"
  }

  user_data = base64encode(templatefile("script/user_data_script_ubuntu.sh", {
    aws_region             = local.region
    ubuntu_password_secret = aws_secretsmanager_secret.ubuntu_password.id
    private_key_secret     = aws_secretsmanager_secret.private_key.id
  }))

  depends_on = [
    module.vpc.natgw_ids,
    aws_secretsmanager_secret.ubuntu_password
  ]
}

# ------------------------------------------------------------
# Security group for EC2 Ubuntu instance
# ------------------------------------------------------------
resource "aws_security_group" "ec2_ubuntu" {
  name_prefix = "${local.name}-ubuntu-"
  description = "EC2 Ubuntu instance SG for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------
# IAM role for EC2 Ubuntu instance
# ------------------------------------------------------------
resource "aws_iam_role" "ec2_ubuntu_role" {
  name_prefix = "${local.name}-ec2-ubuntu-role-"

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
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation",
    aws_iam_policy.ec2_ubuntu.arn
  ]
}

resource "aws_iam_policy" "ec2_ubuntu" {
  name_prefix = "${local.name}-ec2-ubuntu-"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:SendCommand"
        ],
        Resource = [
          "arn:aws:ec2:${local.region}:${local.account_id}:instance/*",
          "arn:aws:ssm:${local.region}:${local.account_id}:document/SSM-SessionManagerRunShell"
        ],
        Condition = {
          BoolIfExists = {
            "ssm:SessionDocumentAccessCheck" : "true"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeInstanceProperties",
        ],
        "Resource" : [
          "arn:aws:ssm:*:*:session/$${aws:username}-*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances"
        ],
        "Resource" : [
          "arn:aws:ec2:${local.region}:${local.account_id}:instance/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ],
        "Resource" : [
          "arn:aws:ssm:*:*:session/$${aws:username}-*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ],
        Resource = aws_kms_key.workshop.arn
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = [
          aws_secretsmanager_secret.private_key.id,
          aws_secretsmanager_secret.ubuntu_password.id
        ]
      },
      {
        Effect   = "Allow",
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ubuntu_instance_profile" {
  role = aws_iam_role.ec2_ubuntu_role.name
}