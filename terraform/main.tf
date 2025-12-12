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
# IAM ROLE + INSTANCE PROFILE FOR EC2 (MUST FOR ECR ACCESS)
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
}
 
# ============================================================
# USER-DATA → INSTALL DOCKER, LOGIN TO ECR, RUN STRAPI
# ============================================================
 
# compute full image string (if image_uri provided use it, else use ECR repo + tag)
locals {
  full_image = var.image_uri != "" ? var.image_uri : "${aws_ecr_repository.strapi.repository_url}:${var.image_tag}"
}

# then in your user_data heredoc replace the FULL_IMAGE definition with:
# (if you use public ECR replace aws_ecrpublic_repository... accordingly)

locals {
  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              FULL_IMAGE="${local.full_image}"

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

              if docker ps -a --format '{{.Names}}' | grep -q '^strapi$'; then
                docker rm -f strapi || true
              fi

              docker run -d -p 1337:1337 \
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
    Name = "aditya"
  }
}