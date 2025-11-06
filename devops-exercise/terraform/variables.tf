variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "knova"
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "bastion_allowed_cidr" {
  description = "CIDR ranges allowed to SSH into bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # tighten to your IP before apply
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "db_username" {
  description = "Postgres database username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Postgres database password (sensitive)"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "db_name" {
  description = "Postgres database name"
  type        = string
  default     = "appdb"
}