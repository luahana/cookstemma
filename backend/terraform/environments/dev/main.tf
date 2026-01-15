# Dev Environment
# Simplified setup: No ALB, No NAT Gateway, Public ECS tasks

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state storage
  backend "s3" {
    bucket         = "pairing-planet-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "pairing-planet-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data source to get ECR repository (created by shared terraform)
data "aws_ecr_repository" "main" {
  name = var.ecr_repository_name
}

# Data source to get Frontend ECR repository (created by shared terraform)
data "aws_ecr_repository" "frontend" {
  name = "${var.ecr_repository_name}-frontend"
}

# VPC Module - No private subnets, no NAT for dev
module "vpc" {
  source = "../../modules/vpc"

  project_name           = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  az_count               = 2
  create_private_subnets = true  # Need private for RDS
  create_nat_gateway     = false # No NAT for dev
}

# Secrets Module
module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment

  # Database
  db_username = var.db_username
  db_password = var.db_password
  db_host     = module.rds.address
  db_port     = "5432"
  db_name     = var.db_name

  # JWT
  jwt_secret_key = var.jwt_secret_key

  # OAuth
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret

  # Encryption
  encryption_key = var.encryption_key

  # Firebase
  firebase_credentials = var.firebase_credentials

  # S3
  s3_access_key = var.s3_access_key
  s3_secret_key = var.s3_secret_key
  s3_bucket     = var.s3_bucket
  s3_region     = var.s3_region
}

# RDS Module - Minimal instance for dev
module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_security_groups = [module.ecs.security_group_id]

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 50
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  multi_az                = false
  backup_retention_period = 0  # Free tier doesn't support backups
  snapshot_identifier     = var.rds_snapshot_identifier
}

# ALB Module - For stable DNS endpoint (HTTP only, no custom domain)
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 4000
  health_check_path = "/actuator/health"
  certificate_arn   = null  # No HTTPS for dev, HTTP only

  # Enable frontend routing
  enable_frontend            = true
  frontend_port              = 3000
  frontend_health_check_path = "/"
}

# ECS Module - With ALB for stable DNS
module "ecs" {
  source = "../../modules/ecs"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids # Public subnets for dev
  container_image = "${data.aws_ecr_repository.main.repository_url}:dev-latest"
  container_port = 4000
  task_cpu       = 512
  task_memory    = 1024
  desired_count  = 1
  assign_public_ip = true # Still need public IP since no NAT gateway

  # ALB configuration
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_blue_arn
  use_code_deploy       = false  # No blue-green for dev

  # S3 bucket for application
  s3_bucket = var.s3_bucket

  # Secrets
  secret_arns           = module.secrets.all_secret_arns
  database_secret_arn   = module.secrets.database_secret_arn
  jwt_secret_arn        = module.secrets.jwt_secret_arn
  oauth_secret_arn      = module.secrets.oauth_secret_arn
  encryption_secret_arn = module.secrets.encryption_secret_arn
  s3_secret_arn         = module.secrets.s3_secret_arn
  firebase_secret_arn   = module.secrets.firebase_secret_arn
}

# ECS Frontend Module - Next.js application
module "ecs_frontend" {
  source = "../../modules/ecs-frontend"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  container_image  = "${data.aws_ecr_repository.frontend.repository_url}:dev-latest"
  container_port   = 3000
  task_cpu         = 256
  task_memory      = 512
  desired_count    = 1
  assign_public_ip = true

  # ALB configuration
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.frontend_target_group_arn
}
