terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# Get AWS Account ID
# -------------------------
data "aws_caller_identity" "current" {}

# -------------------------
# Ubuntu 22.04 AMI
# -------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# -------------------------
# VPC & Subnets
# -------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================
# IAM ROLE + INSTANCE PROFILE FOR EC2 (REQUIRED FOR PRIVATE ECR)
# ============================================================
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-role-aditya"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile-aditya"
  role = aws_iam_role.ec2_role.name
}

# ============================================================
# SECURITY GROUPS — EC2 & RDS
# ============================================================
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-aditya"
  description = "Allow HTTP & SSH for Strapi"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.strapi_port
    to_port     = var.strapi_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "strapi-sg-aditya"
    Owner = "aditya"
  }
}

resource "aws_security_group" "strapi_rds_sg" {
  name        = "strapi-rds-sg-aditya"
  description = "Allow EC2 to reach RDS"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "strapi-rds-sg-aditya"
    Owner = "aditya"
  }
}

resource "aws_security_group_rule" "allow_ec2_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.strapi_rds_sg.id
  source_security_group_id = aws_security_group.strapi_sg.id
}

# ============================================================
# RDS SUBNET GROUP + RDS INSTANCE
# ============================================================
resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "strapi-db-subnet-group-aditya"
  subnet_ids = data.aws_subnets.default_subnets.ids

  tags = {
    Name  = "strapi-db-subnet-group-aditya"
    Owner = "aditya"
  }
}

resource "aws_db_instance" "strapi_rds" {
  identifier              = "strapi-db-aditya"
  allocated_storage       = 20
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  username                = "strapi"
  password                = "strapi123"
  db_name                 = "strapi_db"
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.strapi_rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.strapi_db_subnet_group.name

  tags = {
    Name  = "strapi-db-aditya"
    Owner = "aditya"
  }
}

# ============================================================
# PRIVATE ECR REPOSITORY (declared so locals can reference it)
# ============================================================
resource "aws_ecr_repository" "strapi" {
  name = var.ecr_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name  = "strapi-ecr-repo"
    Owner = "aditya"
  }
}

# ============================================================
# LOCALS & USER-DATA — install docker, login to ECR and run Strapi
# ============================================================
locals {
  # if a full image URI is provided by CI/CD use it, otherwise construct from private ECR repo + tag
  full_image = var.image_uri != "" ? var.image_uri : "${aws_ecr_repository.strapi.repository_url}:${var.image_tag}"

  user_data = <<-EOF
              #!/bin/bash
              set -e

              apt-get update -y
              apt-get install -y docker.io awscli jq
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # small wait to ensure instance metadata is available
              sleep 10

              FULL_IMAGE="${local.full_image}"
              ECR_REGISTRY="${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

              echo "Logging into ECR registry: $${ECR_REGISTRY}"
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $${ECR_REGISTRY}

              echo "Pulling image $${FULL_IMAGE}"
              for i in 1 2 3 4 5; do
                if docker pull $${FULL_IMAGE}; then
                  echo "Pulled $${FULL_IMAGE} successfully"
                  break
                else
                  echo "docker pull failed (attempt $${i}), retrying in 10s"
                  sleep 10
                fi
              done

              # Stop & remove existing container if present
              if docker ps -a --format '{{.Names}}' | grep -q '^strapi$'; then
                docker rm -f strapi || true
              fi

              # Run container
              docker run -d -p ${var.strapi_port}:1337 \
                --name strapi \
                -e DATABASE_CLIENT=postgres \
                -e DATABASE_HOST=${aws_db_instance.strapi_rds.address} \
                -e DATABASE_PORT=5432 \
                -e DATABASE_NAME=strapi_db \
                -e DATABASE_USERNAME=strapi \
                -e DATABASE_PASSWORD=strapi123 \
                -e DATABASE_SSL=true \
                -e DATABASE_SSL__REJECT_UNAUTHORIZED=false \
                -e HOST=0.0.0.0 \
                -e PORT=1337 \
                $${FULL_IMAGE}

              EOF
}

# ============================================================
# EC2 INSTANCE
# ============================================================
resource "aws_instance" "strapi" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data            = local.user_data

  tags = {
    Name  = "strapi-ubuntu-ec2-aditya"
    Owner = "aditya"
  }
}

# ============================================================
# OUTPUTS
# ============================================================
output "ec2_public_ip" {
  description = "Public IP of the Strapi EC2 instance"
  value       = aws_instance.strapi.public_ip
}

output "deployed_image" {
  description = "Image that the instance will pull"
  value       = local.full_image
}
