variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-3"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive = true
}

# or with a map
variable "aws_conf" {
  type = map(string)
  description = "My aws conf with a map"
  sensitive = true
  default = {
    "name" = "value"
  }
}

# or even better in object form
variable "aws_conf_obj" {
  type = object({
    region = string
    access_key = string
    secret_key = string
  })
  description = "My aws conf in object form"
  sensitive = true
  default = {
    region = "eu-west-3"
    access_key = "my-access-key"
    secret_key = "my-secret-key"
  }
}

variable "website_bucket_name" {
  type = string
  description = "Website bucket name"
  default = "aelion-2603-bucket-website-borisn"
}