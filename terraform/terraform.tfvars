aws_region       = "ap-south-1"
instance_type    = "t2.micro"
key_name         = "GIAN"

# DO NOT set image_uri
image_uri        = ""

# image_tag will come from CD workflow
image_tag        = "latest" # fallback only

allowed_ssh_cidr = "0.0.0.0/0"
strapi_port      = 1337

app_keys             = "key1,key2,key3,key4"
api_token_salt       = "api_token_salt_123"
admin_jwt_secret     = "admin_jwt_secret_123"
transfer_token_salt  = "transfer_token_salt_123"
jwt_secret           = "jwt_secret_123"
