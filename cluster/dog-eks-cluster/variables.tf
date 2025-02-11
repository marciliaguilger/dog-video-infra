variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use"
  type        = string
  default     = "dog"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "The CIDR block for the public subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "The CIDR block for the public subnet B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "The CIDR block for the private subnet A"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  description = "The CIDR block for the private subnet B"
  type        = string
  default     = "10.0.4.0/24"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}


variable "eks_cluster_role_arn" {
  description = "The ARN of the EKS cluster role"
  type        = string
}

variable "eks_node_group_role_arn" {
  description = "The ARN of the EKS node group role"
  type        = string
}

variable "cluster_arn" {
  description = "The ARN of the cluster"
  type = string
  default = "arn:aws:iam::764549915701:role/eks-cluster-role"
}