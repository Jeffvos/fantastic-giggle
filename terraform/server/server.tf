variable "ami" {

}
variable "size" {
  default = "t2.micro"
}

variable "subnet_id" {

}
variable "security_groups" {
  type = list(any)
}
resource "aws_instance" "web" {
  ami                    = var.ami
  instance_type          = var.size
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_groups
  tags = {
    "Name"        = "module server"
    "Environment" = "Test"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}


