output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.simple_ec2.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.simple_ec2.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.simple_ec2.public_dns
}

output "ssh_command" {
  description = "Ready-to-use SSH command (Amazon Linux uses ec2-user)"
  value       = "ssh -i aleion-tf-2609.pem ec2-user@${aws_instance.simple_ec2.public_ip}"
}
