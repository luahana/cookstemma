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
    bucket         = "cookstemma-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "cookstemma-terraform-locks"
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

# Data source to get Web ECR repository (created by shared terraform)
data "aws_ecr_repository" "web" {
  name = "${var.ecr_repository_name}-web"
}

# Data source to get Translator ECR repository (created by shared terraform)
data "aws_ecr_repository" "translator" {
  name = "${var.ecr_repository_name}-translator"
}

# Data source to get Image Processor ECR repository (created by shared terraform)
data "aws_ecr_repository" "image_processor" {
  name = "${var.ecr_repository_name}-image-processor"
}

# Data source to get Suggestion Verifier ECR repository (created by shared terraform)
data "aws_ecr_repository" "suggestion_verifier" {
  name = "${var.ecr_repository_name}-suggestion-verifier"
}

# Data source to get Keyword Generator ECR repository (created by shared terraform)
data "aws_ecr_repository" "keyword_generator" {
  name = "${var.ecr_repository_name}-keyword-generator"
}

# Data source for S3 bucket (images)
data "aws_s3_bucket" "images" {
  bucket = var.s3_bucket
}

# =============================================================================
# STANDALONE SECURITY GROUPS FOR LAMBDAS
# Created first to break circular dependency with RDS
# =============================================================================
resource "aws_security_group" "lambda_translation" {
  name        = "${var.project_name}-${var.environment}-translator-lambda-sg"
  description = "Security group for translation Lambda"
  vpc_id      = module.vpc.vpc_id

  # Outbound: Allow all (needed for RDS, Secrets Manager, Gemini API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-translator-lambda-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "lambda_suggestion_verifier" {
  name        = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-sg"
  description = "Security group for suggestion verifier Lambda"
  vpc_id      = module.vpc.vpc_id

  # Outbound: Allow all (needed for RDS, Secrets Manager, Gemini API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-suggestion-verifier-lambda-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "lambda_keyword_generator" {
  name        = "${var.project_name}-${var.environment}-keyword-generator-lambda-sg"
  description = "Security group for keyword generator Lambda"
  vpc_id      = module.vpc.vpc_id

  # Outbound: Allow all (needed for RDS, Secrets Manager, Gemini API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-keyword-generator-lambda-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# =============================================================================
# STANDALONE SECURITY GROUP FOR ECS WEB
# Created first to break circular dependency with ALB
# =============================================================================
resource "aws_security_group" "ecs_web" {
  name        = "${var.project_name}-${var.environment}-ecs-web-sg"
  description = "Security group for ECS web tasks"
  vpc_id      = module.vpc.vpc_id

  # Ingress will be added by ALB module reference
  # Egress: Allow all (needed for API calls to ALB, external services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-web-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Ingress rule for ECS web - allow traffic from ALB on port 3000
resource "aws_security_group_rule" "ecs_web_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_web.id
  source_security_group_id = module.alb.security_group_id
  description              = "Allow traffic from ALB"
}

# Ingress rule for backend ECS - allow traffic from web container on port 4000 (for Cloud Map SSR calls)
resource "aws_security_group_rule" "backend_from_web" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  security_group_id        = module.ecs.security_group_id
  source_security_group_id = aws_security_group.ecs_web.id
  description              = "Allow SSR calls from web container via Cloud Map"
}

# VPC Module - Keep private subnets for RDS, but no NAT Gateway (saves ~$35/month)
module "vpc" {
  source = "../../modules/vpc"

  project_name           = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  az_count               = 2
  create_private_subnets = true  # Keep private subnets for RDS (more secure)
  create_nat_gateway     = false # Using NAT Instance instead (saves ~$30/mo)
  create_vpc_endpoints   = true  # VPC endpoints for Secrets Manager, SQS, S3
}

# NAT Instance Module - Cost-effective alternative to NAT Gateway (~$4/mo vs ~$35/mo)
# Provides internet access for Lambdas to reach Gemini API
module "nat_instance" {
  source = "../../modules/nat-instance"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = var.vpc_cidr
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  private_route_table_id = module.vpc.private_route_table_id
  instance_type          = "t3.nano"
}

# Service Discovery Module - Cloud Map for internal service-to-service communication
# Enables SSR (Next.js) to call backend API directly without going through ALB (bypasses IP restrictions)
module "service_discovery" {
  source = "../../modules/service-discovery"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# RDS Module - Minimal instance for dev
# Note: Lambda SG is passed here so Lambda can connect to RDS
# RDS stays in private subnet (more secure, no internet access needed)
module "rds" {
  source = "../../modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids  # Private subnets (more secure)
  publicly_accessible     = false                          # Not publicly accessible
  allowed_security_groups = [module.ecs.security_group_id, aws_security_group.lambda_translation.id, aws_security_group.lambda_suggestion_verifier.id, aws_security_group.lambda_keyword_generator.id]

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 50
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  multi_az                = false
  backup_retention_period = 0 # Free tier doesn't support backups
  snapshot_identifier     = var.rds_snapshot_identifier

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
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

# ALB Module - For stable DNS endpoint with HTTPS
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  container_port    = 4000
  health_check_path = "/actuator/health"
  certificate_arn   = var.certificate_arn

  # IP Whitelisting (restrict access in terraform.tfvars)
  # VPC CIDR is always allowed for internal service-to-service communication
  allowed_cidr_blocks = var.allowed_cidr_blocks
  vpc_cidr            = var.vpc_cidr

  # Allow ECS web security group to access ALB (for SSR API calls)
  allowed_security_group_ids = [aws_security_group.ecs_web.id]

  # Enable web routing
  enable_web            = true
  web_port              = 3000
  web_health_check_path = "/"

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
}

# ECS Module - With ALB for stable DNS
module "ecs" {
  source = "../../modules/ecs"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids # Public subnets for dev
  container_image  = "${data.aws_ecr_repository.main.repository_url}:dev-latest"
  container_port   = 4000
  task_cpu         = 512
  task_memory      = 2048
  desired_count    = 1
  assign_public_ip = true # Still need public IP since no NAT gateway
  cpu_architecture = "ARM64" # Graviton for 20% cost savings

  # ALB configuration
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_blue_arn
  use_code_deploy       = false # No blue-green for dev

  # Allow web ECS tasks to access backend via service discovery
  additional_ingress_security_group_ids = [aws_security_group.ecs_web.id]

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

  # CDN URL for images (CloudFront)
  cdn_url_prefix = "https://drms7t3elqlu.cloudfront.net"

  # SQS Configuration for real-time translations (hybrid architecture)
  sqs_translation_queue_url = module.lambda_translation.sqs_queue_url
  sqs_translation_queue_arn = module.lambda_translation.sqs_queue_arn
  sqs_enabled               = true

  # Service Discovery (Cloud Map) - enables internal service-to-service communication
  service_discovery_service_arn = module.service_discovery.backend_service_arn

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
}

# ECS Web Module - Next.js application
module "ecs_web" {
  source = "../../modules/ecs-web"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  container_image  = "${data.aws_ecr_repository.web.repository_url}:dev-latest"
  container_port   = 3000
  task_cpu         = 256
  task_memory      = 512
  desired_count    = 1
  assign_public_ip = true
  cpu_architecture = "ARM64" # Graviton for 20% cost savings

  # ALB configuration
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.web_target_group_arn

  # Use pre-created security group to allow ALB to reference it
  use_existing_security_group = true
  existing_security_group_id  = aws_security_group.ecs_web.id

  # Internal API URL for SSR (bypasses ALB IP restrictions)
  internal_api_url = module.service_discovery.backend_api_url

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
}

# Lambda Translation Module - Gemini-powered content translation
# Uses public subnets with public IPs to reach both RDS and Gemini API
module "lambda_translation" {
  source = "../../modules/lambda-translation"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids # Private subnets with NAT for Gemini API

  # ECR repository (created by shared terraform)
  ecr_repository_url = data.aws_ecr_repository.translator.repository_url

  # Secrets
  database_secret_arn = module.secrets.database_secret_arn
  gemini_api_key      = var.gemini_api_key

  # Use pre-created security group to break circular dependency
  use_existing_security_group = true
  existing_security_group_id  = aws_security_group.lambda_translation.id

  # Lambda configuration
  schedule_expression            = "rate(5 minutes)"
  memory_size                    = 512
  timeout                        = 600 # 10 minutes to handle large recipe batches
  reserved_concurrent_executions = -1 # No reserved concurrency (account quota limit)

  # CDN URL for content moderation (image validation)
  cdn_url_prefix = "https://drms7t3elqlu.cloudfront.net"

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn

  # x86_64 for faster CI builds (no QEMU emulation)
  architecture = "arm64"
}

# Lambda Image Processing Module - Parallel variant generation with Step Functions
module "lambda_image_processing" {
  source = "../../modules/lambda-image-processing"

  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = var.s3_bucket
  s3_bucket_arn  = data.aws_s3_bucket.images.arn

  # ECR repository (created by shared terraform)
  ecr_repository_url = data.aws_ecr_repository.image_processor.repository_url

  # Lambda configuration
  memory_size                    = 1024
  timeout                        = 60
  reserved_concurrent_executions = -1 # No reserved concurrency (account quota limit)

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn

  # x86_64 for faster CI builds (no QEMU emulation)
  architecture = "arm64"
}

# Lambda Suggestion Verifier Module - AI-powered validation of user suggestions
# Uses public subnets with public IPs to reach both RDS and Gemini API
module "lambda_suggestion_verifier" {
  source = "../../modules/lambda-suggestion-verifier"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids # Private subnets with NAT for Gemini API

  # ECR repository (created by shared terraform)
  ecr_repository_url = data.aws_ecr_repository.suggestion_verifier.repository_url

  # Secrets (reuse Gemini secret from translation module)
  database_secret_arn = module.secrets.database_secret_arn
  gemini_secret_arn   = module.lambda_translation.gemini_secret_arn

  # Use pre-created security group to break circular dependency
  use_existing_security_group = true
  existing_security_group_id  = aws_security_group.lambda_suggestion_verifier.id

  # Lambda configuration
  schedule_expression            = "rate(5 minutes)"
  memory_size                    = 512
  timeout                        = 300
  reserved_concurrent_executions = -1 # No reserved concurrency (account quota limit)

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
}

# Lambda Keyword Generator Module - AI-powered multilingual keyword generation
# Uses public subnets with public IPs to reach both RDS and Gemini API
module "lambda_keyword_generator" {
  source = "../../modules/lambda-keyword-generator"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids # Private subnets with NAT for Gemini API

  # ECR repository (created by shared terraform)
  ecr_repository_url = data.aws_ecr_repository.keyword_generator.repository_url

  # Secrets (reuse Gemini secret from translation module)
  database_secret_arn = module.secrets.database_secret_arn
  gemini_secret_arn   = module.lambda_translation.gemini_secret_arn

  # Use pre-created security group to break circular dependency
  use_existing_security_group = true
  existing_security_group_id  = aws_security_group.lambda_keyword_generator.id

  # Lambda configuration
  schedule_expression            = "rate(5 minutes)"
  memory_size                    = 512
  timeout                        = 600 # 10 minutes
  reserved_concurrent_executions = -1  # No reserved concurrency (account quota limit)

  # CloudWatch Alarms
  sns_alarm_topic_arn = aws_sns_topic.alerts.arn
}

# CloudFront CDN Module - Image delivery with WebP auto-selection
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name                   = var.project_name
  environment                    = var.environment
  s3_bucket_name                 = var.s3_bucket
  s3_bucket_regional_domain_name = data.aws_s3_bucket.images.bucket_regional_domain_name
  s3_bucket_arn                  = data.aws_s3_bucket.images.arn

  # CDN configuration
  enable_webp_selector = true
  price_class          = "PriceClass_100" # US, Canada, Europe (cheapest)
  lambda_code_path     = "${path.module}/../../../lambda/webp-selector"
}

# =============================================================================
# ROUTE53 DNS - Custom domain for dev.cookstemma.com
# =============================================================================

# Data source for existing Route53 hosted zone
data "aws_route53_zone" "main" {
  count = var.create_dns_record ? 1 : 0
  name  = var.domain_name
}

# A record for dev.cookstemma.com pointing to ALB
resource "aws_route53_record" "dev" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "${var.environment}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

# =============================================================================
# CLOUDWATCH ALARMS - SNS Topic for Email Notifications
# =============================================================================

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-${var.environment}-alerts"
  display_name      = "Cookstemma ${title(var.environment)} Infrastructure Alerts"
  kms_master_key_id = "alias/aws/sns" # Use default AWS managed key for encryption

  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Email subscription (requires manual confirmation via email)
resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
