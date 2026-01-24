#!/bin/bash
# Manual deployment script for keyword-generator Lambda
# Usage: ./deploy.sh <environment>
# Example: ./deploy.sh dev

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION="us-east-2"
PROJECT_NAME="cookstemma"
ECR_REPO="${PROJECT_NAME}-keyword-generator"
LAMBDA_NAME="${PROJECT_NAME}-${ENVIRONMENT}-keyword-generator"

echo "Deploying keyword-generator Lambda to ${ENVIRONMENT}..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "ECR Registry: ${ECR_REGISTRY}"

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push Docker image
echo "Building Docker image..."
docker build -t ${ECR_REGISTRY}/${ECR_REPO}:latest .

echo "Pushing to ECR..."
docker push ${ECR_REGISTRY}/${ECR_REPO}:latest

# Update Lambda function
echo "Updating Lambda function ${LAMBDA_NAME}..."
aws lambda update-function-code \
    --function-name ${LAMBDA_NAME} \
    --image-uri ${ECR_REGISTRY}/${ECR_REPO}:latest \
    --region ${AWS_REGION}

echo "Waiting for function to be ready..."
aws lambda wait function-updated \
    --function-name ${LAMBDA_NAME} \
    --region ${AWS_REGION}

echo "Deployment complete!"
