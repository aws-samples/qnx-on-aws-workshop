# ------------------------------------------------------------
# EC2 Key pairs
# ------------------------------------------------------------
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key_pair" {
  key_name_prefix = "${local.name}-"
  public_key      = tls_private_key.private_key.public_key_openssh
}

# ------------------------------------------------------------
# Secrets Manager for storing private key
# ------------------------------------------------------------
resource "aws_secretsmanager_secret" "private_key" {
  name_prefix             = "${local.name}-private-key-"
  kms_key_id              = aws_kms_key.workshop.id
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
  name_prefix             = "${local.name}-ubuntu-password-"
  kms_key_id              = aws_kms_key.workshop.id
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ubuntu_password" {
  secret_id     = aws_secretsmanager_secret.ubuntu_password.id
  secret_string = var.ubuntu_user_password
}

# ------------------------------------------------------------
# KMS
# ------------------------------------------------------------
resource "aws_kms_key" "workshop" {
  description             = "KMS CMK for the workshop"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "workshop" {
  name_prefix   = "alias/${local.name}-"
  target_key_id = aws_kms_key.workshop.key_id
}

resource "aws_kms_key_policy" "workshop" {
  key_id = aws_kms_key.workshop.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key_policy_1"
    Statement = [
      {
        Sid    = "Enable IAM permissions"
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          Service = "logs.${local.region}.amazonaws.com"
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
