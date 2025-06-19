# ------------------------------------------------------------
# EC2 Key pairs
# ------------------------------------------------------------
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key_pair" {
  key_name_prefix = "${var.project_name}-"
  public_key      = tls_private_key.private_key.public_key_openssh
}

# ------------------------------------------------------------
# Secrets Manager for storing private key
# ------------------------------------------------------------
resource "aws_secretsmanager_secret" "private_key" {
  name_prefix             = "${var.project_name}-private-key-"
  kms_key_id              = aws_kms_key.kms_key.id
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "private_key" {
  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.private_key.private_key_pem
}

# ------------------------------------------------------------
# Secrets Manager for storing Ubuntu Linux default password
# ------------------------------------------------------------
resource "aws_secretsmanager_secret" "ubuntu_password" {
  name_prefix             = "${var.project_name}-ubuntu-password-"
  kms_key_id              = aws_kms_key.kms_key.id
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ubuntu_password" {
  secret_id     = aws_secretsmanager_secret.ubuntu_password.id
  secret_string = var.ubuntu_user_password
}

# ------------------------------------------------------------
# KMS
# ------------------------------------------------------------
resource "aws_kms_key" "kms_key" {
  description             = "KMS CMK for the workshop"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "kms_alias" {
  name_prefix   = "alias/${var.project_name}-"
  target_key_id = aws_kms_key.kms_key.key_id
}

resource "aws_kms_key_policy" "kms_key_policy" {
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key_policy_1"
    Statement = [
      {
        Sid    = "Enable IAM permissions"
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
          AWS = [
            aws_iam_role.codepipeline.arn,
            aws_iam_role.codebuild.arn,
            "arn:aws:iam::${local.account_id}:root"
          ]
        }
        Resource = "*"
      },
    ]
  })
}
