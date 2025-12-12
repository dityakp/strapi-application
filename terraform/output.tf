output "public_ip" {
  description = "Public IP address of the Strapi EC2 instance"
  value       = aws_instance.strapi.public_ip
}

output "strapi_url" {
  description = "URL to access Strapi"
  value       = "http://${aws_instance.strapi.public_dns}:${var.strapi_port}"
}

output "deployed_image" {
  description = "Image that the instance will pull (repo:tag or image_uri)"
  value       = local.full_image
}
