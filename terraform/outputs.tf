output "hello-world" {
    description = "out puts hello world"
    value = "hello world"
}

output "vpc_id" {
    description = "vpc id output"
    value = aws_vpc.vpc.id
}