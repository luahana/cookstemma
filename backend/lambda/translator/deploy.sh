#!/bin/bash
# Deploy translation Lambda to AWS
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-2}
PROJECT_NAME="pairing-planet"
LAMBDA_NAME="${PROJECT_NAME}-${ENVIRONMENT}-translator"
ECR_REPO="${PROJECT_NAME}-${ENVIRONMENT}-translator"

echo "Deploying translation Lambda to ${ENVIRONMENT}..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

echo "ECR URL: ${ECR_URL}"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build Docker image
echo "Building Docker image..."
docker build -t ${ECR_REPO}:latest .

# Tag for ECR
echo "Tagging image for ECR..."
docker tag ${ECR_REPO}:latest ${ECR_URL}:latest

# Push to ECR
echo "Pushing image to ECR..."
docker push ${ECR_URL}:latest

# Update Lambda function
echo "Updating Lambda function..."
aws lambda update-function-code \
    --function-name ${LAMBDA_NAME} \
    --image-uri ${ECR_URL}:latest \
    --region ${AWS_REGION}

echo "Waiting for Lambda to update..."
aws lambda wait function-updated \
    --function-name ${LAMBDA_NAME} \
    --region ${AWS_REGION}

echo "Deployment complete!"
echo "Lambda ARN: arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${LAMBDA_NAME}"
