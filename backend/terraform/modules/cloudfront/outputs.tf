output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID (for Route53)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cdn_url" {
  description = "CDN URL for images"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "webp_selector_lambda_arn" {
  description = "ARN of the WebP selector Lambda@Edge function"
  value       = var.enable_webp_selector ? aws_lambda_function.webp_selector[0].qualified_arn : null
}
