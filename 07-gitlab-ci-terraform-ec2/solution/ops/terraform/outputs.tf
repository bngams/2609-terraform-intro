output "environment" {
  description = "Environnement deploye"
  value       = var.environment
}

output "public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.srv.public_ip
}

output "public_dns" {
  description = "DNS public de l'instance EC2"
  value       = aws_instance.srv.public_dns
}

output "web_url" {
  description = "URL du serveur nginx"
  value       = "http://${aws_instance.srv.public_ip}"
}

output "ssh_command" {
  description = "Commande SSH prete a l'emploi (Amazon Linux -> ec2-user)"
  value       = "ssh -i <votre-cle-privee>.pem ec2-user@${aws_instance.srv.public_ip}"
}
