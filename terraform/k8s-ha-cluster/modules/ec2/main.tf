# EC2 Module for HA Kubernetes Cluster

resource "aws_instance" "node" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  # IAM instance profile is optional - only set if provided
  iam_instance_profile   = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  user_data = var.user_data != "" ? var.user_data : null

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

