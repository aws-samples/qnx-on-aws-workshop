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

output "ec2_instance_qnx_safety_instance_id" {
  description = "QNX Safety instance ID"
  value       = module.ec2_instance_qnx_safety.id
}

output "ec2_instance_qnx_safety_private_dns" {
  description = "QNX Safety private DNS name"
  value       = module.ec2_instance_qnx_safety.private_dns
}

output "ec2_instance_qnx_safety_private_ip" {
  description = "QNX Safety private IP address"
  value       = module.ec2_instance_qnx_safety.private_ip
}

# Comment out the following code block in case you use QNX Neutrino.

# output "ec2_instance_qnx_neutrino_instance_id" {
#   description = "QNX Neutrino instance ID"
#   value       = module.ec2_instance_qnx_neutrino.id
# }

# output "ec2_instance_qnx_neutrino_private_dns" {
#   description = "QNX Neutrino private DNS name"
#   value       = module.ec2_instance_qnx_neutrino.private_dns
# }

# output "ec2_instance_qnx_neutrino_private_ip" {
#   description = "QNX Neutrino private IP address"
#   value       = module.ec2_instance_qnx_neutrino.private_ip
# }

output "codecommit_repository_url" {
  description = "CodeCommit repository URL"
  value       = aws_codecommit_repository.workshop.clone_url_http
}

output "codecommit_repository_name" {
  description = "CodeCommit repository name"
  value       = aws_codecommit_repository.workshop.repository_name
}
