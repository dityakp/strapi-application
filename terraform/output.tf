output "public_ip" {
  value = aws_instance.strapi.public_ip
}

output "strapi_url" {
  value = "http://${aws_instance.strapi.public_dns}:${var.strapi_port}"
}

output "deployed_image" {
  value = local.full_image
}

output "ec2_public_ip" {
  description = "Public IP of the Strapi EC2 instance"
  value       = aws_instance.strapi.public_ip
}