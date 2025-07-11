# ------------------------------------------------------------
# CodeBuild project
# ------------------------------------------------------------
resource "aws_codebuild_project" "workshop" {
  name           = var.project_name
  description    = "CodeBuild project for ${var.project_name}"
  build_timeout  = "10"
  service_role   = aws_iam_role.codebuild.arn
  encryption_key = aws_kms_key.kms_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "BUILD_PROJECT_NAME"
      value = var.build_project_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "QNX_HOST"
      value = module.ec2_instance_qnx.private_dns
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "QNX_CUSTOM_AMI_ID"
      value = var.qnx_custom_ami_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "VPC_ID"
      value = module.vpc.vpc_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "PRIVATE_SUBNET_ID"
      value = module.vpc.private_subnets[0]
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "VPC_CIDR_BLOCK"
      value = module.vpc.vpc_cidr_block
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "KEY_PAIR_NAME"
      value = aws_key_pair.key_pair.key_name
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "PRIVATE_KEY_SECRET_ID"
      value = aws_secretsmanager_secret.private_key.id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "KMS_KEY_ID"
      value = aws_kms_key.kms_key.id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "TF_VERSION"
      value = var.codebuild_terraform_version
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "TF_BACKEND_S3"
      value = aws_s3_bucket.codepipeline_bucket.bucket
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      # Use the string (not the reference to aws_cloudwatch_log_group resource) to avoid cyclic reference for KMS CMK
      group_name = "/aws/codebuild/${var.project_name}"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
  source_version = "refs/heads/main"

  vpc_config {
    vpc_id = module.vpc.vpc_id
    subnets = [
      module.vpc.private_subnets[0],
      module.vpc.private_subnets[1]
    ]
    security_group_ids = [
      aws_security_group.codebuild.id
    ]
  }
}

# ------------------------------------------------------------
# Security group for CodeBuild
# ------------------------------------------------------------
resource "aws_security_group" "codebuild" {
  name_prefix = "${var.project_name}-codebuild-"
  description = "CodeBuild SG for ${var.project_name}"
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
# IAM for CodeBuild
# ------------------------------------------------------------
resource "aws_iam_role" "codebuild" {
  name_prefix = "${var.project_name}-codebuild-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_custom_policy" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_admin_access" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_ec2_full_access" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_policy" "codebuild" {
  name_prefix = "${var.project_name}-codebuild-"

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
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:*",
        ],
        Resource = [
          # Use the string (not the reference to aws_cloudwatch_log_group resource) to avoid cyclic reference for KMS CMK
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/codebuild/*",
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/codebuild/*:log-stream:*"
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
          "iam:AddRoleToInstanceProfile"
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
}

# ------------------------------------------------------------
# S3 for CodePipeline
# ------------------------------------------------------------
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket_prefix = "${var.project_name}-codepipeline-bucket-"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket_ownership" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
  bucket     = aws_s3_bucket.codepipeline_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.codepipeline_bucket_ownership]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.codepipeline_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# CodePipeline
# ------------------------------------------------------------
resource "aws_codestarconnections_connection" "github" {
  name          = var.project_name
  provider_type = "GitHub"
}

resource "aws_codepipeline" "codepipeline" {
  name          = var.project_name
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.kms_key.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_user}/${var.github_repo}"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.workshop.name
      }
    }
  }
}

# ------------------------------------------------------------
# IAM for CodePilepine
# ------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  name_prefix = "${var.project_name}-codepipeline-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_custom_policy" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_iam_policy" "codepipeline" {
  name_prefix = "${var.project_name}-codepipeline-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject",
        ]
        Resource = [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
        ]
        Resource = [aws_codestarconnections_connection.github.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [aws_codebuild_project.workshop.id]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey"
        ]
        Resource = [aws_kms_key.kms_key.arn]
      }
    ]
  })
}

# ------------------------------------------------------------
# IAM for CloudWatch Event (EnvetBridge) for CodePilepine event-based change detection
# ------------------------------------------------------------
resource "aws_iam_role" "cwe_codepipeline" {
  name_prefix = "${var.project_name}-cwe-codepipeline-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cwe_codepipeline_custom_policy" {
  role       = aws_iam_role.cwe_codepipeline.name
  policy_arn = aws_iam_policy.cwe_codepipeline.arn
}

resource "aws_iam_policy" "cwe_codepipeline" {
  name_prefix = "${var.project_name}-cwe-codepipeline-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = [
          aws_codepipeline.codepipeline.arn
        ]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.kms_key.arn
  depends_on        = [aws_kms_key_policy.kms_key_policy]
}
