output "public_ip" {
  description = "Public IP address of the Strapi EC2 instance"
  value       = aws_instance.strapi.public_ip
}

output "strapi_url" {
  description = "URL to access Strapi"
  value       = "http://${aws_instance.strapi.public_dns}:${var.strapi_port}"
}

output "deployed_image" {
  description = "Image deployed on EC2"
  value = var.image_uri != "" ? var.image_uri : "public.ecr.aws/r6f7t4j8/strapi-repo-aditya:${var.image_tag}"
}

