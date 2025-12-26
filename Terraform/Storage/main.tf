resource "aws_s3_bucket" "web_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public_policy" {
  bucket                  = aws_s3_bucket.web_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.web_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.web_bucket.arn}/*"
      }
    ]
  })
}

# Corrected Object Resources
resource "aws_s3_object" "index_html" {
  # Change 'dashboard_bucket' to 'web_bucket'
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/../Automation Project/index.html"
  etag         = filemd5("${path.module}/../Automation Project/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "style_css" {
  # Change 'dashboard_bucket' to 'web_bucket'
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "style.css"
  source       = "${path.module}/../Automation Project/style.css"
  etag         = filemd5("${path.module}/../Automation Project/style.css")
  content_type = "text/css"
}

resource "aws_s3_object" "script_js" {
  # Change 'dashboard_bucket' to 'web_bucket'
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "script.js"
  source       = "${path.module}/../Automation Project/script.js"
  etag         = filemd5("${path.module}/../Automation Project/script.js")
  content_type = "application/javascript"
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
