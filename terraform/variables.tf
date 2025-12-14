variable "aws_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH. Set to null if you don't want an SSH key."
  type        = string
  nullable    = true
  default     = null
}

variable "strapi_port" {
  description = "Port Strapi listens on"
  type        = number
  default     = 1337
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ecr_repo_name" {
  description = "Name for the private ECR repository"
  type        = string
  default     = "strapi-repo-aditya"
}

variable "image_tag" {
  description = "Docker image tag to pull (overridden by CI/CD)."
  type        = string
  default     = "latest"
}

variable "image_uri" {
  description = "Full Docker image URI"
  type        = string
}

variable "app_keys" {}
variable "api_token_salt" {}
variable "admin_jwt_secret" {}
variable "transfer_token_salt" {}
variable "jwt_secret" {}
