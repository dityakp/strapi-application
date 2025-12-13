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

# ============================================================
# ACCOUNT INFO
# ============================================================

data "aws_caller_identity" "current" {}

# ============================================================
# AMI
# ============================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ============================================================
# NETWORK
# ============================================================

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
# IAM — EC2 → ECR PULL ACCESS
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
# SECURITY GROUP — STRAPI
# ============================================================

resource "aws_security_group" "strapi_sg" {
  name   = "strapi-sg-aditya"
  vpc_id = data.aws_vpc.default.id

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

# ============================================================
# RDS
# ============================================================

resource "aws_security_group" "strapi_rds_sg" {
  name   = "strapi-rds-sg-aditya"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_ec2_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.strapi_rds_sg.id
  source_security_group_id = aws_security_group.strapi_sg.id
}

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
# LOCALS — IMAGE COMES FROM MANUAL ECR
# ============================================================

locals {
  image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}:${var.image_tag}"

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y docker.io awscli
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    aws ecr get-login-password --region ${var.aws_region} \
      | docker login --username AWS --password-stdin \
        ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    docker pull ${local.image_uri}

    docker rm -f strapi || true

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
      ${local.image_uri}
  EOF
}

# ============================================================
# EC2
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
    Name = "strapi-ec2-aditya"
  }
}
