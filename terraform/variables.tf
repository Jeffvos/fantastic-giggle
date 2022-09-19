variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

variable "variables_sub_cidr" {
  description = "Cidr block fro the var subnet"
  type        = string
  default     = "10.0.202.0/24"
}

variable "variable_sub_az" {
  description = "AZ used var subnet"
  type        = string
  default     = "us-east-1"
}

variable "var_sub_auto_ip" {
  description = "automatic ip assignment for var subnet"
  type        = bool
  default     = true
}
variable "environment" {
  type    = string
  default = "PROD"
}