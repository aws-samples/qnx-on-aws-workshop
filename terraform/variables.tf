variable "ubuntu_user_password" {
  description = "Ubuntu user password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_user" {
  description = "GitHub user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}
