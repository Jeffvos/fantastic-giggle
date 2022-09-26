output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}

output "size" {
  description = "size of instance"
  value = aws_instance.web.instance_type
}