provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
# Criar a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc"
  }
}
# Criar a Subnet Pública em duas AZs
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a",
    "kubernetes.io/cluster/dog-eks-cluster" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b",
    "kubernetes.io/cluster/dog-eks-cluster" = "shared"
    "kubernetes.io/role/elb"            = "1"
  }
}
# Criar a Subnet Privada em duas AZs
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-a",
    "kubernetes.io/cluster/dog-eks-cluster"    = "shared"
    "kubernetes.io/role/internal-elb"         = "1"

  }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-b",
    "kubernetes.io/cluster/dog-eks-cluster"     = "shared"
    "kubernetes.io/role/internal-elb"         = "1"

  }
}
# Criar o Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}
# Criar a Tabela de Rotas para a Subnet Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}
# Associar a Tabela de Rotas Pública às Subnets Públicas
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
# Criar a Tabela de Rotas para a Subnet Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  }
}

# Associar a Tabela de Rotas Privada às Subnets Privadas
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Criar o NAT Gateway
resource "aws_eip" "nat" {
  vpc = true
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "main-nat"
  }
}
# Adicionar rota para o NAT Gateway na Tabela de Rotas Privada
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}


# Criar Subnet Group para RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "rds-subnet-group"
  }
}

# Criar Security Group para RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306            # Porta padrão do MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Permite comunicação de toda a VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = "eks-cluster-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_eks_cluster" "dog_development" {
  name     = "dog-eks-cluster"
  role_arn = var.eks_cluster_role_arn
  vpc_config {
    subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.private_a.id,aws_subnet.private_b.id]
  }
}
resource "aws_iam_role_policy_attachment" "node_group_policy" {
  role       = "eks-node-group-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = "eks-node-group-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = "eks-node-group-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_eks_node_group" "dog_node_group" {
  cluster_name    = aws_eks_cluster.dog_development.name
  node_group_name = "dog-node-group"
  node_role_arn   = var.eks_node_group_role_arn
  subnet_ids      = [aws_subnet.private_a.id,aws_subnet.private_b.id,aws_subnet.public_a.id,aws_subnet.public_b.id]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t3.medium"]
  capacity_type  = "SPOT"

}
data "aws_eks_cluster_auth" "dog_development" {
  name = aws_eks_cluster.dog_development.name
  depends_on = [aws_eks_cluster.dog_development]
}
provider "kubernetes" {
  host                   = aws_eks_cluster.dog_development.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.dog_development.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.dog_development.token
}

resource "kubernetes_service_account" "dog-service-account" {
  metadata {
    name      = "dog-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.cluster_arn
    }
  }
}

resource "aws_iam_policy" "eks_load_balancer_policy" {
  name        = "EKSLoadBalancerPolicy"
  description = "Permissões necessárias para criar LoadBalancers no EKS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eks_role" {
  name = "EKSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_role_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = aws_iam_policy.eks_load_balancer_policy.arn
}