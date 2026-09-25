# s3 static website url
output "website_url_manual" {
  value = "http://${aws_s3_bucket.website_bucket.bucket}.s3-website.${var.aws_conf_obj.region}.amazonaws.com"
  sensitive = true
}

output "website_url" {
  value = aws_s3_bucket.website_bucket.bucket_regional_domain_name
  sensitive = true
}