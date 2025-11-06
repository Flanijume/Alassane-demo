locals {
  name = "${var.project}-demo"
}

# --- VPC ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
}

# --- Bastion (Jumpbox) ---
resource "aws_key_pair" "bastion" {
  key_name   = "${local.name}-bastion"
  public_key = file("./bastion_id_rsa.pub")
}

module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-bastion-sg"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = var.bastion_allowed_cidr
  egress_rules        = ["all-all"]
}

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.6"

  name = "${local.name}-bastion"
  ami_ssm_parameter = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.bastion_sg.security_group_id]
  key_name = aws_key_pair.bastion.key_name
}

# --- EKS ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}

# --- Security Group for DB allowing only EKS nodes ---
resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "DB Security Group for Postgres access"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow Postgres from private subnets
resource "aws_security_group_rule" "db_ingress_pg" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
}

# --- Custom DB Subnet Group to keep RDS inside our VPC ---
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "${local.name}-db-subnet-group"
  description = "Subnet group for RDS inside ${local.name} VPC"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name = "${local.name}-db-subnet-group"
  }
}

# --- RDS Postgres ---
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier              = "${local.name}-pg"
  engine                  = "postgres"
  engine_version          = "15"
  family                  = "postgres15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20

  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 5432
  multi_az                = false
  publicly_accessible     = false
  storage_encrypted       = true
  backup_retention_period = 7
  skip_final_snapshot     = true

  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name  # ✅ Correct reference

  depends_on = [
    module.vpc,
    aws_security_group.db,
    aws_db_subnet_group.db_subnet_group
  ]
}
# --- S3 bucket for app logs or artifacts ---
module "logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1"

  bucket        = "${local.name}-logs"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}