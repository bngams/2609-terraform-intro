# Use the default VPC so the example stays simple (no VPC/subnet to create)
data "aws_vpc" "default" {
  default = true
}

# Data source for AMI (Amazon Machine Image)
data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# SECURITY GROUP: allow inbound SSH (22) and HTTP (80), all outbound
resource "aws_security_group" "ec2_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# EC2 INSTANCE - T3 Micro
resource "aws_instance" "simple_ec2" {
  ami                    = data.aws_ami.ami.id
  instance_type          = var.instance_type
  # name of an existing EC2 key pair in AWS
  # key_name               = var.key_name
  # attach the security group to the instance
  # vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = var.instance_name
  }
}
