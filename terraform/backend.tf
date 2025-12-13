terraform {
  backend "s3" {
    bucket         = "strapi-terraform-state-aditya"
    key            = "task6/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
