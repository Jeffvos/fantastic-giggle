/*
Sample terraform code for aws deployments
JeffVos
*/

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  team        = "api_mgmt_dev"
  application = "api_corp"
  server_name = "fantastic-giggle-${var.environment}-api-${var.variable_sub_az}"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = var.vpc_name
    Environment = "demo_environment"
    Terraform   = "true"
    Region      = data.aws_region.current.name
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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2-micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.priv_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/Jeffvos/fantastic-giggle.git /tmp",
      "sudo sh /tmp/assets/setup-web.sh"
    ]
  }

  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application
  }
  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2-micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_2"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.priv_key_pem
    host        = self.public_ip
  }
  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application
  }
}

# resource "aws_s3_bucket" "s3_bucket" {
#   bucket = "awesome_bucket_${random_id.radom_idness.hex}"
#   tags = {
#     Name    = "s3_bucket"
#     Purpose = "sample code"
#   }
# }

# resource "aws_s3_bucket_acl" "s3_bucket_acl" {
#   bucket = aws_s3_bucket.s3_bucket.id
#   acl    = "private"
# }

# resource "aws_security_group" "new_security_group" {
#   name        = "web_ser_inbound"
#   description = "allow inbound traffic on tcp 443"
#   vpc_id      = aws_vpc.vpc.id
#   ingress = [
#     {
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "allow 443 tcp"
#     from_port   = 443
#     protocol    = "tcp"
#     to_port     = 443
#     self = false
#     ipv6_cidr_blocks = []
#     prefix_list_ids = []
#     security_groups = []
#     }
#   ]
#   tags = {
#     "Name" = "ser inbound"
#   }
# }

# resource "random_id" "radom_idness" {
#   byte_length = 16
# }

resource "aws_subnet" "tf-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.variables_sub_cidr
  availability_zone       = var.variable_sub_az
  map_public_ip_on_launch = true
  tags = {
    "Name" = "sub-public-${var.variable_sub_az}"
  }
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "local_file" "priv_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyAWSKey.pem"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myAWSKey"
  public_key = tls_private_key.generated.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}
#not for prod
resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    description      = "allow ssh from all ips "
  }]
  egress = [{
    description      = "default change"
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []

  }]
}
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web-${terraform.workspace}"
  vpc_id      = aws_vpc.vpc.id
  description = "webtraffic"
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    description      = "web traffic "
    },
    {
      cidr_blocks      = ["0.0.0.0/0"]
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      self             = false
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      description      = " ssl web traffic "
  }]
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "allow all ip and ports outbound "
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.vpc.id
  description = "ICMP ping"
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    description      = "allow icmp ping"
  }]
  egress = [{
    description      = "allow outbound"
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
  }]

}
resource "aws_instance" "web_server_2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2-micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated_key.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.priv_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/Jeffvos/fantastic-giggle.git /tmp",
      "sudo sh /tmp/assets/setup-web.sh"
    ]
  }

  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application
  }
  lifecycle {
    ignore_changes = [
      security_groups
    ]
  }
}

module "server" {
  source    = "./server"
  ami       = data.aws_ami.ubuntu.id
  subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
  security_groups = [
    aws_security_group.vpc-ping.id,
    aws_security_group.ingress-ssh.id,
    aws_security_group.vpc-web.id
  ]
}

output "public_ip" {
  value = module.server.public_ip
}

output "public_dns" {
  value = module.server.public_dns
}

module "server_subnet_1" {
  source    = "./server"
  ami       = data.aws_ami.ubuntu.id
  subnet_id = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups = [
    aws_security_group.vpc-ping.id,
    aws_security_group.ingress-ssh.id,
    aws_security_group.vpc-web.id
  ]
}