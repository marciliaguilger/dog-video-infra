# Configuração do Provedor AWS
provider "aws" {
  region = "us-east-1"
  profile = "pos"
}

resource "aws_dynamodb_table" "videos" {
    name         = "videos"  
    billing_mode = "PAY_PER_REQUEST"  

    # Definição das chaves
    hash_key  = "videoId"
    
    attribute {
      name = "videoId"
      type = "S"  
    }
}
  