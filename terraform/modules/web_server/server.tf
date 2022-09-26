variable "ami" {
}
variable "size" {
  default = "t2.micro"
}

variable "subnet_id" {

}
variable "user" {

}

variable "security_groups" {
  type = list(any)
}

variable "key_name" {

}

variable "private_key" {
}

resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.size
  vpc_security_group_ids      = var.security_groups
  associate_public_ip_address = true
  key_name                    = var.key_name
  connection {
    user        = var.user
    private_key = var.private_key
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://githuburl" / tmp,
    ]
  }
  tags = {
    "Name"        = "webser"
    "Environment" = "test"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}

