aws_region       = "ap-south-1"
instance_type    = "t2.micro"
key_name         = "GIAN"

# DO NOT set image_uri
image_uri        = ""

# image_tag will come from CD workflow
image_tag        = "latest" # fallback only

allowed_ssh_cidr = "0.0.0.0/0"
strapi_port      = 1337
