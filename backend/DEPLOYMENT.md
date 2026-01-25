# AWS Deployment Guide

This document describes how to deploy the Cookstemma backend to AWS using Terraform and GitHub Actions.

## Architecture Overview

```
                    ┌─────────────────────────────────────────────────────┐
                    │                    AWS Cloud                         │
                    │                                                      │
  Internet ───────► │  ┌─────────┐    ┌─────────┐    ┌─────────┐         │
                    │  │   ALB   │───►│   ECS   │───►│   RDS   │         │
                    │  │(staging/│    │ Fargate │    │Postgres │         │
                    │  │  prod)  │    │         │    │         │         │
                    │  └─────────┘    └─────────┘    └─────────┘         │
                    │                      │                              │
                    │                      ▼                              │
                    │              ┌───────────────┐                      │
                    │              │    Secrets    │                      │
                    │              │    Manager    │                      │
                    │              └───────────────┘                      │
                    └─────────────────────────────────────────────────────┘
```

## Environments

| Environment | Branch | Deployment Type | Cost Estimate |
|-------------|--------|-----------------|---------------|
| Dev | `dev` | Rolling Update | ~$33/month |
| Staging | `staging` | Blue/Green | ~$117/month |
| Production | `master` | Blue/Green | ~$177/month |

### Dev Environment
- No ALB (direct ECS public IP access)
- No NAT Gateway
- Single task instance
- db.t3.micro RDS

### Staging/Production Environment
- ALB with HTTPS
- NAT Gateway for private subnets
- Blue/Green deployment via CodeDeploy
- Multi-AZ RDS (prod only)

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured locally
3. **Terraform** >= 1.0 installed
4. **Domain name** (for staging/prod HTTPS)
5. **ACM Certificate** created for your domain

## Initial Setup

### 1. Create S3 Backend for Terraform State

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket cookstemma-terraform-state \
  --region ap-northeast-2 \
  --create-bucket-configuration LocationConstraint=ap-northeast-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cookstemma-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name cookstemma-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2
```

### 2. Create ACM Certificate (for staging/prod)

```bash
# Request certificate
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS \
  --region ap-northeast-2
```

### 3. Deploy Shared Resources (ECR)

```bash
cd terraform/shared

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Secrets

Add these secrets in GitHub repository settings:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key |

### 5. Deploy Environment Infrastructure

```bash
# For each environment (dev, staging, prod)
cd terraform/environments/dev

# Copy and fill in variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with actual values

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Deployment Flow

### Development
```
Push to dev branch → GitHub Actions → Build & Test → Push to ECR → Rolling Update ECS
```

### Staging/Production
```
Push to staging/master → GitHub Actions → Build & Test → Push to ECR → CodeDeploy Blue/Green
```

## Manual Deployment Commands

### Update ECS Service (Dev - Rolling)
```bash
# Force new deployment
aws ecs update-service \
  --cluster cookstemma-dev-cluster \
  --service cookstemma-dev-service \
  --force-new-deployment
```

### Create CodeDeploy Deployment (Staging/Prod)
```bash
# Register new task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create deployment
aws deploy create-deployment \
  --application-name cookstemma-staging \
  --deployment-group-name cookstemma-staging-dg \
  --revision revisionType=AppSpecContent,appSpecContent={content='...'}
```

## Monitoring

### View ECS Logs
```bash
# Tail logs
aws logs tail /ecs/cookstemma-dev --follow
```

### Check Service Status
```bash
aws ecs describe-services \
  --cluster cookstemma-dev-cluster \
  --services cookstemma-dev-service
```

### Check Deployment Status
```bash
aws deploy get-deployment --deployment-id <deployment-id>
```

## Rollback

### Dev (Rolling)
The previous task definition revision can be deployed:
```bash
aws ecs update-service \
  --cluster cookstemma-dev-cluster \
  --service cookstemma-dev-service \
  --task-definition cookstemma-dev:<previous-revision>
```

### Staging/Prod (CodeDeploy)
Use the AWS Console or CLI to stop and rollback:
```bash
aws deploy stop-deployment --deployment-id <deployment-id> --auto-rollback-enabled
```

## Troubleshooting

### ECS Task Won't Start
1. Check CloudWatch logs: `/ecs/cookstemma-{env}`
2. Verify security group allows outbound traffic
3. Check Secrets Manager permissions
4. Verify task definition CPU/memory settings

### Health Check Failing
1. Ensure `/actuator/health` endpoint is accessible
2. Check container port mapping (4000)
3. Verify Spring Boot is binding to 0.0.0.0

### Database Connection Issues
1. Check RDS security group allows ECS security group
2. Verify secrets in Secrets Manager
3. Check RDS is in correct subnet

## Cost Optimization Tips

1. **Dev**: Use FARGATE_SPOT for lower costs
2. **Staging**: Consider scheduled scaling (down overnight)
3. **Production**: Use Reserved Capacity for predictable workloads
4. **All**: Enable RDS auto-pause if supported
