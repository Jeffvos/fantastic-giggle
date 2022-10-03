output "hello-world" {
  description = "out puts hello world"
  value       = "hello world"
}

output "vpc_id" {
  description = "vpc id output"
  value       = aws_vpc.vpc.id
}

output "public_url" {
  description = "webservers public url"
  value       = "https://${aws_instance.web_server.private_ip}:8080/index.html"
}

output "vpc_info" {
  description = "vpc information"
  value       = "${aws_vpc.vpc.tags.Environment} vpc has an id of ${aws_vpc.vpc.id}"
}

output "public_ip" {
  description = "this is the public ip of the ec2"
  value       = aws_instance.web_server.public_ip
}