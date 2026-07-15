terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. Publicly readable, unencrypted S3 bucket, no versioning, no logging ---
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "upwind-demo-bad-bucket-${var.suffix}"
}

resource "aws_s3_bucket_acl" "bad_bucket_acl" {
  bucket = aws_s3_bucket.bad_bucket.id
  acl    = "public-read" # BAD: publicly readable bucket
}

resource "aws_s3_bucket_public_access_block" "bad_bucket_pab" {
  bucket                  = aws_s3_bucket.bad_bucket.id
  block_public_acls       = false # BAD: allows public ACLs
  block_public_policy     = false # BAD: allows public bucket policies
  ignore_public_acls      = false
  restrict_public_buckets = false
}
# No aws_s3_bucket_server_side_encryption_configuration -> BAD: unencrypted at rest
# No aws_s3_bucket_versioning -> BAD: no versioning / ransomware protection
# No aws_s3_bucket_logging -> BAD: no access logging

# --- 2. Security group wide open to the internet on SSH/RDP ---
resource "aws_security_group" "bad_sg" {
  name        = "upwind-demo-bad-sg"
  description = "Intentionally over-permissive security group"

  ingress {
    description = "SSH open to the world" # BAD
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP open to the world" # BAD
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # BAD: unrestricted egress
  }
}

# --- 3. Overly permissive IAM policy ---
resource "aws_iam_policy" "bad_policy" {
  name        = "upwind-demo-bad-policy"
  description = "Intentionally over-permissive IAM policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"     # BAD: wildcard action
        Resource = "*"     # BAD: wildcard resource
      }
    ]
  })
}

# --- 4. Unencrypted, publicly accessible RDS instance with hardcoded credentials ---
resource "aws_db_instance" "bad_db" {
  identifier             = "upwind-demo-bad-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "SuperSecret123!" # BAD: hardcoded secret, should use Secrets Manager
  publicly_accessible    = true               # BAD: internet-facing database
  storage_encrypted      = false              # BAD: unencrypted storage
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.bad_sg.id]
}

# --- 5. Unencrypted EBS volume ---
resource "aws_ebs_volume" "bad_volume" {
  availability_zone = "${var.aws_region}a"
  size              = 10
  encrypted         = false # BAD: unencrypted block storage
}
