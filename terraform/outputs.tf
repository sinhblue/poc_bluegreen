output "terraform_output_summary" {
  description = "Summary of all outputs"
  value = {
    ec2 = {
      instance_id = aws_instance.app_server.id
      public_ip   = aws_instance.app_server.public_ip
      private_ip  = aws_instance.app_server.private_ip
    }
    aurora = {
      cluster_endpoint        = aws_rds_cluster.aurora_cluster.endpoint
      cluster_reader_endpoint = aws_rds_cluster.aurora_cluster.reader_endpoint
      database_name           = aws_rds_cluster.aurora_cluster.database_name
      engine_version          = aws_rds_cluster.aurora_cluster.engine_version
      master_username         = var.db_master_username
    }
    secrets = {
      password_secret_name = aws_secretsmanager_secret.aurora_password.name
    }
    parameter_groups = {
      pg14_cluster_param_group   = aws_rds_cluster_parameter_group.aurora_pg14_cluster.name
      pg14_instance_param_group  = aws_db_parameter_group.aurora_pg14_instance.name
      pg15_cluster_param_group   = aws_rds_cluster_parameter_group.aurora_pg15_cluster.name
      pg15_instance_param_group  = aws_db_parameter_group.aurora_pg15_instance.name
    }
    security = {
      ec2_security_group_id    = aws_security_group.ec2_sg.id
      aurora_security_group_id = aws_security_group.aurora_sg.id
    }
  }
}
