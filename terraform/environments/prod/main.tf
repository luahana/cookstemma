# Production Environment
# Full setup: ALB, NAT Gateway, Private ECS, Blue/Green deployment, Multi-AZ RDS

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state storage
  # Uncomment after creating the S3 bucket
  # backend "s3" {
  #   bucket         = "pairing-planet-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "pairing-planet-terraform-locks"
  # }
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

# VPC Module - Full setup with NAT
module "vpc" {
  source = "../../modules/vpc"

  project_name           = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  az_count               = 2
  create_private_subnets = true
  create_nat_gateway     = true
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

# RDS Module - Production grade with Multi-AZ
module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_security_groups = [module.ecs.security_group_id]

  instance_class          = "db.t3.medium"
  allocated_storage       = 50
  max_allocated_storage   = 200
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  multi_az                = true # Multi-AZ for production
  backup_retention_period = 14
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 4000
  health_check_path = "/actuator/health"
  certificate_arn   = var.certificate_arn
}

# ECS Module - Private subnets with ALB
module "ecs" {
  source = "../../modules/ecs"

  project_name    = var.project_name
  environment     = var.environment
  aws_region      = var.aws_region
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  container_image = "${data.aws_ecr_repository.main.repository_url}:prod-latest"
  container_port  = 4000
  task_cpu        = 1024
  task_memory     = 2048
  desired_count   = 2 # Run 2 tasks for production
  assign_public_ip = false

  # ALB configuration
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_blue_arn
  use_code_deploy       = true

  # S3 bucket for application
  s3_bucket = var.s3_bucket

  # Secrets
  secret_arns           = module.secrets.all_secret_arns
  database_secret_arn   = module.secrets.database_secret_arn
  jwt_secret_arn        = module.secrets.jwt_secret_arn
  oauth_secret_arn      = module.secrets.oauth_secret_arn
  encryption_secret_arn = module.secrets.encryption_secret_arn
  s3_secret_arn         = module.secrets.s3_secret_arn
}

# CodeDeploy Module
module "codedeploy" {
  source = "../../modules/codedeploy"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name

  prod_listener_arn       = module.alb.https_listener_arn
  test_listener_arn       = module.alb.test_listener_arn
  target_group_blue_name  = module.alb.target_group_blue_name
  target_group_green_name = module.alb.target_group_green_name

  # Linear deployment for production - safer rollout
  deployment_config_name = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
  termination_wait_time  = 10
}
