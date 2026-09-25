variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-3"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  sensitive   = true
}

# ami-06121aa3085b6f918 -> 64 bits (x86), uefi-preferred
# ami-03748c04dc81412c6 -> 64 bits (Arm), uefi
# NOTE: an x86 AMI requires an x86 instance type (t3.micro),
# an Arm AMI requires an Arm instance type (t4g.micro).
variable "ami_id" {
  description = "The AMI id used to launch the EC2 instance (x86 by default)"
  type        = string
  default     = "ami-06121aa3085b6f918"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "aelion-2609-simple-ec2"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair in AWS to attach to the instance"
  type        = string
  default     = "aleion-tf-2609"
}
