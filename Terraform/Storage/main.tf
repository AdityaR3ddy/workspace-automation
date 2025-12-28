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

  # THIS IS THE FIX: It forces Terraform to wait for the block to be removed
  depends_on = [aws_s3_bucket_public_access_block.allow_public_policy]

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

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/../../Automation-project/index.html"
  etag         = filemd5("${path.module}/../../Automation-project/index.html")

  content_type = "text/html"
}

resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "style.css"
  source       = "${path.module}/../../Automation-project/style.css"
  etag         = filemd5("${path.module}/../../Automation-project/style.css")
  content_type = "text/css"
}

resource "aws_s3_object" "script_js" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "script.js"
  source       = "${path.module}/../../Automation-project/script.js"
  etag         = filemd5("${path.module}/../../Automation-project/script.js")
  content_type = "application/javascript"
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}
