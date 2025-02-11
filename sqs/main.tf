provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_sqs_queue" "terraform_queue" {
  name                      = "video-queue"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}