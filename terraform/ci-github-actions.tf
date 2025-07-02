# ------------------------------------------------------------
# GitHub Actions CI/CD Configuration
# This file contains GitHub Actions OIDC and IAM resources
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
