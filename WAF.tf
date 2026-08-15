# 1. WAF Resource Block
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider    = aws.us_east_1
  name        = "jeffery-cloudfront-waf"
  description = "WAF for CloudFront static site"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "jeffery-cloudfront-waf-metrics"
    sampled_requests_enabled   = true
  }

  # NEST THE RULE BLOCK INSIDE THE RESOURCE
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }
}