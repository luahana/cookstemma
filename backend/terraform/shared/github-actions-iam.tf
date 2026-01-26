# =============================================================================
# GitHub Actions OIDC IAM Roles
# =============================================================================
# These roles allow GitHub Actions to authenticate with AWS using OIDC tokens
# instead of long-lived credentials. Each environment has its own role with
# branch/environment restrictions.

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  aws_account_id           = data.aws_caller_identity.current.account_id
}

# =============================================================================
# DEV ENVIRONMENT
# =============================================================================

resource "aws_iam_role" "github_actions_dev" {
  name        = "github-actions-cookstemma-dev"
  description = "GitHub Actions OIDC role for cookstemma dev environment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repository}:ref:refs/heads/dev",
            "repo:${var.github_repository}:environment:dev"
          ]
        }
      }
    }]
  })

  tags = {
    Name        = "github-actions-cookstemma-dev"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy" "github_actions_dev_lambda" {
  name = "LambdaDeployPolicy"
  role = aws_iam_role.github_actions_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration"
      ]
      Resource = "arn:aws:lambda:${var.aws_region}:${local.aws_account_id}:function:cookstemma-dev-*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_dev_ecr" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_actions_dev_ecs" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# =============================================================================
# PROD ENVIRONMENT
# =============================================================================

resource "aws_iam_role" "github_actions_prod" {
  name        = "github-actions-cookstemma-prod"
  description = "GitHub Actions OIDC role for cookstemma prod environment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repository}:ref:refs/heads/master",
            "repo:${var.github_repository}:environment:production"
          ]
        }
      }
    }]
  })

  tags = {
    Name        = "github-actions-cookstemma-prod"
    Environment = "prod"
  }
}

resource "aws_iam_role_policy" "github_actions_prod_lambda" {
  name = "LambdaDeployment"
  role = aws_iam_role.github_actions_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "LambdaDeployment"
      Effect = "Allow"
      Action = [
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration"
      ]
      Resource = "arn:aws:lambda:${var.aws_region}:${local.aws_account_id}:function:cookstemma-prod-*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_prod_ecr" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_actions_prod_ecs" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "github_actions_prod_codedeploy" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}
