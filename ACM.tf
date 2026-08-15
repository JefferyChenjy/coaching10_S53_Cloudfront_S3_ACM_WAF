# Step 4: Request an ACM SSL/TLS Certificate for Custom Domain
# To front your static website with CloudFront using your custom domain (jeffery.sctp-sandbox.com), you need an SSL/TLS certificate from AWS Certificate Manager (ACM).
# Crucial Rule for CloudFront: CloudFront requires ACM certificates to be issued in the us-east-1 (N. Virginia) region, regardless of which region your S3 bucket or main provider is using.

# step4 option1. Request ACM Certificate in us-east-1

# resource "aws_acm_certificate" "cert" {
#   provider                  = aws.us_east_1
#   domain_name               = "jeffery.sctp-sandbox.com"
#   validation_method         = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# step4 option2- use module. Request ACM Certificate in us-east-1

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.us_east_1
  }

  domain_name = "jeffery.sctp-sandbox.com"
  zone_id     = "Z00541411T1NGPV97B5C0" # Your Route 53 Hosted Zone ID

  wait_for_validation = true
}


# """
# Update your aws_cloudfront_distribution.s3_distribution resource in your Terraform file with the following changes:

# Add aliases = ["jeffery.sctp-sandbox.com"].

# Update the viewer_certificate block to use acm_certificate_arn instead of cloudfront_default_certificate = true.
# """

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket1.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = ["jeffery.sctp-sandbox.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = module.acm.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}


# Step 6: Create Route 53 Alias Record
# Now we need to create a Route 53 Alias record so that traffic to jeffery.sctp-sandbox.com points directly to your CloudFront distribution.
# Why an Alias record instead of a CNAME?
# Route 53 Alias records resolve directly to AWS resource IP addresses with better performance, zero latency/DNS lookup cost, and allow alias routing at the zone apex (root domain).

data "aws_route53_zone" "selected" {
  name         = "sctp-sandbox.com."
  private_zone = false
}

#create Alias record for CloudFront distribution
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "jeffery.sctp-sandbox.com"
  type    = "A"     

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


