# ------------------------------------------------------------
# GitHub Actions CI/CD Configuration
# This file contains GitHub Actions OIDC, IAM resources, and repository variables
# when ci_cd_provider = "github-actions"
# ------------------------------------------------------------

# ------------------------------------------------------------
# GitHub Actions OIDC Provider for AWS
# ------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # GitHub Actions OIDC provider thumbprint list
  # These thumbprints are used to verify the authenticity of the GitHub Actions OIDC provider
  # Reference: https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "${var.project_name}-github-actions-oidc"
  }
}

# ------------------------------------------------------------
# IAM Role for GitHub Actions
# ------------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  name_prefix = "${var.project_name}-github-actions-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_user}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# ------------------------------------------------------------
# IAM Policy for GitHub Actions
# ------------------------------------------------------------
resource "aws_iam_policy" "github_actions" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  name_prefix = "${var.project_name}-github-actions-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          aws_s3_bucket.ci_artifacts[0].arn,
          "${aws_s3_bucket.ci_artifacts[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = [
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/github-actions/*",
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/github-actions/*:log-stream:*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ],
        Resource = "*"
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
          aws_secretsmanager_secret.private_key.id
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:TagResource"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:*"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetRole",
          "iam:GetInstanceProfile",
          "iam:CreateRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteInstanceProfile",
          "iam:TagRole",
          "iam:TagInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole",
        ],
        "Resource" : "arn:aws:iam::${local.account_id}:role/qnx-on-aws-ws-pl-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
        ],
        "Resource" : "arn:aws:ssm:${var.aws_region}::parameter/aws/service/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_custom_policy" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions[0].arn
}

# ------------------------------------------------------------
# GitHub Repository Variables for GitHub Actions
# These variables are automatically created in the GitHub repository
# and used by the GitHub Actions workflow for CI/CD
# ------------------------------------------------------------

# AWS Region
resource "github_actions_variable" "aws_region" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

# AWS Role ARN for OIDC authentication
resource "github_actions_variable" "aws_role_arn" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.github_actions[0].arn

  depends_on = [aws_iam_role.github_actions]
}

# Build project name
resource "github_actions_variable" "build_project_name" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "BUILD_PROJECT_NAME"
  value         = var.build_project_name
}

# Custom QNX AMI ID
resource "github_actions_variable" "qnx_custom_ami_id" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "QNX_CUSTOM_AMI_ID"
  value         = var.qnx_custom_ami_id
}

# VPC ID
resource "github_actions_variable" "vpc_id" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "VPC_ID"
  value         = module.vpc.vpc_id

  depends_on = [module.vpc]
}

# Private Subnet ID
resource "github_actions_variable" "private_subnet_id" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "PRIVATE_SUBNET_ID"
  value         = module.vpc.private_subnets[0]

  depends_on = [module.vpc]
}

# VPC CIDR Block
resource "github_actions_variable" "vpc_cidr_block" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "VPC_CIDR_BLOCK"
  value         = module.vpc.vpc_cidr_block

  depends_on = [module.vpc]
}

# EC2 Key Pair Name
resource "github_actions_variable" "key_pair_name" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "KEY_PAIR_NAME"
  value         = aws_key_pair.key_pair.key_name

  depends_on = [aws_key_pair.key_pair]
}

# Private Key Secret ID
resource "github_actions_variable" "private_key_secret_id" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "PRIVATE_KEY_SECRET_ID"
  value         = aws_secretsmanager_secret.private_key.id

  depends_on = [aws_secretsmanager_secret.private_key]
}

# KMS Key ID
resource "github_actions_variable" "kms_key_id" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "KMS_KEY_ID"
  value         = aws_kms_key.kms_key.id

  depends_on = [aws_kms_key.kms_key]
}

# Terraform Version
resource "github_actions_variable" "tf_version" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "TF_VERSION"
  value         = var.terraform_version
}

# Terraform Backend S3 Bucket
resource "github_actions_variable" "tf_backend_s3" {
  count = var.ci_cd_provider == "github-actions" ? 1 : 0

  repository    = var.github_repo
  variable_name = "TF_BACKEND_S3"
  value         = aws_s3_bucket.ci_artifacts[0].bucket

  depends_on = [aws_s3_bucket.ci_artifacts]
}
