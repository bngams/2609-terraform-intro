# CREATE AN S3 BUCKET
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_bucket_name
  tags = {
    Name        = "My static website bucket"
  }
}

# CONFIGURE THE BUCKET AS A STATIC WEBSITE
resource "aws_s3_bucket_website_configuration" "website_bucket_conf" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

# UPLOAD MY FILES TO THE BUCKET
resource "aws_s3_object" "website_bucket_index_file" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "index.html"
  source = "${path.module}/assets/index.html"
  content_type = "text/html; charset=utf-8" 
}

# UPLOAD MY FILES TO THE BUCKET
resource "aws_s3_object" "website_bucket_error_file" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "error.html"
  source = "${path.module}/assets/error.html"
  content_type = "text/html; charset=utf-8" 
}

# MAKE THE BUCKET PUBLIC
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ADD A BUCKET POLICY TO ALLOW PUBLIC READ ACCESS TO THE OBJECTS
# resource "aws_s3_bucket_policy" "website_bucket_policy" {
#   bucket = aws_s3_bucket.website_bucket.id
#   policy = <<EOT
#   {
#       "Version": "2012-10-17",
#       "Statement": [
#           {
#               "Sid": "PublicReadGetObject",
#               "Effect": "Allow",
#               "Principal": "*",
#               "Action": [
#                   "s3:GetObject"
#               ],
#               "Resource": [
#                   "${aws_s3_bucket.website_bucket.arn}/*"
#               ]
#           }
#       ]
#   }
#   EOT
# }

resource "aws_s3_bucket_policy" "website_bucket_policy_data" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {

    sid = "PublicReadGetObject"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.website_bucket.arn,
      "${aws_s3_bucket.website_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_ownership_controls" "my-static-website" {
  bucket = aws_s3_bucket.website_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

