# 1. Bucket Policy to Allow CloudFront (OAC) Access
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.bucket1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket1.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# 2. Create Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac-jeffery"
  description                       = "OAC for S3 static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

