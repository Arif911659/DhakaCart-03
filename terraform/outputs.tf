# Terraform Outputs
# These show important information after infrastructure is created

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_info" {
  description = "Database information (Docker container)"
  value = {
    host     = "database"  # Docker container name
    port     = 5432
    database = var.db_name
    user     = var.db_user
    note     = "PostgreSQL runs as Docker container on each EC2 instance"
  }
  sensitive = false
}

output "redis_info" {
  description = "Redis information (Docker container)"
  value = {
    host = "redis"  # Docker container name
    port = 6379
    note = "Redis runs as Docker container on each EC2 instance"
  }
  sensitive = false
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb = aws_security_group.alb.id
    web = aws_security_group.web.id
    # Note: Database and Redis security groups exist but not used (containers run on same instance)
    database = aws_security_group.database.id
    redis    = aws_security_group.redis.id
  }
}

output "autoscaling_group_name" {
  description = "Name of the auto-scaling group"
  value       = aws_autoscaling_group.web.name
}

output "key_pair_name" {
  description = "Name of the auto-generated key pair"
  value       = aws_key_pair.dhakacart_key.key_name
}

output "private_key_file" {
  description = "Path to the downloaded private key file"
  value       = "${path.module}/${var.project_name}-key.pem"
}

output "ssh_instructions" {
  description = "Instructions for SSH access"
  value = <<-EOT
    🔑 SSH Key Information:
    - Key Pair Name: ${aws_key_pair.dhakacart_key.key_name}
    - Private Key File: ${path.module}/${var.project_name}-key.pem
    
    📝 To SSH into an EC2 instance:
    1. Get instance IP from AWS Console (EC2 → Instances)
    2. Use: ssh -i ${path.module}/${var.project_name}-key.pem ubuntu@<instance-ip>
    3. Make sure the key file has correct permissions: chmod 400 ${path.module}/${var.project_name}-key.pem
  EOT
}

output "instructions" {
  description = "Instructions for next steps"
  value = <<-EOT
    ✅ Infrastructure created successfully!
    
    📋 Next Steps:
    1. Access your application: http://${aws_lb.main.dns_name}
    2. Database: PostgreSQL container (host: database, port: 5432)
    3. Redis: Redis container (host: redis, port: 6379)
    4. Note: Database and Redis run as Docker containers on each EC2 instance
    
    🔑 SSH Key:
    - Private key saved to: ${path.module}/${var.project_name}-key.pem
    - Key pair name: ${aws_key_pair.dhakacart_key.key_name}
    - Use: ssh -i ${path.module}/${var.project_name}-key.pem ubuntu@<instance-ip>
    
    🔒 Security Note:
    - Database and Redis are in private subnets (not accessible from internet)
    - Only web servers can access them
    - Private key file is saved locally (keep it secure!)
    
    💰 Cost Saving Tip:
    - Run 'terraform destroy' when done to avoid charges
  EOT
}

