output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "private_key" {
  description = "Private key of the key pair"
  value       = tls_private_key.private_key.private_key_openssh
  sensitive   = true
}

output "private_key_secrets_manager_secret_id" {
  description = "Private Key secret id"
  value       = aws_secretsmanager_secret.private_key.id
}

output "ec2_instance_ubuntu_instance_id" {
  description = "EC2 Ubuntu instance id"
  value       = module.ec2_instance_ubuntu.id
}

output "ec2_instance_qnx_instance_id" {
  description = "QNX instance ID"
  value       = module.ec2_instance_qnx.id
}

output "ec2_instance_qnx_private_dns" {
  description = "QNX private DNS name"
  value       = module.ec2_instance_qnx.private_dns
}

output "ec2_instance_qnx_private_ip" {
  description = "QNX private IP address"
  value       = module.ec2_instance_qnx.private_ip
}

output "github_repository_url" {
  description = "GitHub repository URL"
  value       = "https://github.com/${var.github_user}/${var.github_repo}"
}

output "github_repository_name" {
  description = "GitHub repository name"
  value       = var.github_repo
}
