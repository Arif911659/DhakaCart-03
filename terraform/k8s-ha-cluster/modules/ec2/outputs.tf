output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.node.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.node.private_ip
}

output "public_ip" {
  description = "Public IP address (if in public subnet)"
  value       = aws_instance.node.public_ip
}

