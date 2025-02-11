# Configuração do Provedor AWS
provider "aws" {
  region = "us-east-1"
  profile = "pos"
}

resource "aws_s3_bucket" "dogapplicationfiles" {
  bucket = "dogapplicationfiles"

  tags = {
    Name        = "dogapplicationfiles"
    Environment = "production"
  }
}