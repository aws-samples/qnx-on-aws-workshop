# ------------------------------------------------------------
# Shared CI/CD Resources
# This file contains resources shared between CodeBuild and GitHub Actions
# ------------------------------------------------------------

# ------------------------------------------------------------
# S3 Bucket for CI/CD Artifacts and Terraform State
# ------------------------------------------------------------
resource "aws_s3_bucket" "ci_artifacts" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket_prefix = "${var.project_name}-ci-artifacts-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-ci-artifacts"
    Purpose = var.ci_cd_provider == "codebuild" ? "CodePipeline artifacts and Terraform state" : "Terraform state"
  }
}

resource "aws_s3_bucket_ownership_controls" "ci_artifacts_ownership" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket = aws_s3_bucket.ci_artifacts[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "ci_artifacts_acl" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket     = aws_s3_bucket.ci_artifacts[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.ci_artifacts_ownership]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ci_artifacts_encrypt" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket = aws_s3_bucket.ci_artifacts[0].id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "ci_artifacts_versioning" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket = aws_s3_bucket.ci_artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ci_artifacts_block" {
  count = var.ci_cd_provider != "none" ? 1 : 0

  bucket                  = aws_s3_bucket.ci_artifacts[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
