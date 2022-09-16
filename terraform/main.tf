provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    #nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_public_rtb"
    Terraform = "true"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    #gateway_id = aws_internet_gateway.internet_gateway.id
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_private_rtb"
    Terraform = "true"
  }
}

resource "aws_route_table_association" "public" {
  depends_on = [
    aws_subnet.public_subnets
  ]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on = [
    aws_subnet.private_subnets
  ]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "name" = "demo_igw"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
  depends_on = [
    aws_internet_gateway.internet_gateway
  ]
  tags = {
    "Name" = "demo_igw_eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [
    aws_subnet.public_subnets
  ]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    "Name" = "demo_nat_gateway"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2-micro"
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name = "Ubuntu EC2 Instance"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-05f3141013eebdc12"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnets["public_subnet_2"].id
  vpc_security_group_ids = ["<SECURITY_GROUP"]
  tags = {
    "Terraform" = "true"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "s3_bucket_for_data_fantastic_giggle"
  tags = {
    Name    = "s3_bucket"
    Purpose = "sample code"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}