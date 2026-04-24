# EC2 instance for application
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = var.ec2_instance_type
  key_name               = var.key_pair_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint = aws_rds_cluster.aurora_cluster.endpoint
    db_name     = "poc_bluegreen"
    db_user     = var.db_master_username
  }))

  tags = {
    Name = "poc-bluegreen-server"
  }

  depends_on = [aws_rds_cluster.aurora_cluster]
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.app_server.public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = aws_instance.app_server.private_ip
}
