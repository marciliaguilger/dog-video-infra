# Configuração do Provedor AWS
provider "aws" {
  region = "us-east-1"
  profile = "pos"
}

resource "aws_dynamodb_table" "users" {
    name         = "users"  
    billing_mode = "PAY_PER_REQUEST"  

    # Definição das chaves
    hash_key  = "userId"
    
    attribute {
      name = "userId"
      type = "S"  
    }
}
  