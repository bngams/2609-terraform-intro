# VPC par defaut, pour rester simple (pas de VPC/subnet a creer)
data "aws_vpc" "default" {
  default = true
}

# Derniere AMI Amazon Linux 2023 x86_64
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# La key pair est CREEE par Terraform a partir de la cle publique fournie par le
# secret CI/CD -> aucune cle a pre-creer a la main dans la console AWS.
resource "aws_key_pair" "lab" {
  key_name   = "aelion-2609-${var.environment}"
  public_key = var.ssh_public_key
}

# Security group : entrant SSH (22) + HTTP (80), tout sortant autorise
resource "aws_security_group" "ec2_sg" {
  name        = "aelion-2609-${var.environment}-sg"
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
    Name        = "aelion-2609-${var.environment}-sg"
    Environment = var.environment
  }
}

# L'instance EC2
resource "aws_instance" "srv" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Petit serveur nginx pour avoir quelque chose a voir dans le navigateur,
  # avec le nom de l'environnement -> on distingue dev de prod d'un coup d'oeil.
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>Aelion 2609 - environnement ${var.environment}</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  tags = {
    Name        = "aelion-2609-${var.environment}"
    Environment = var.environment
  }
}
