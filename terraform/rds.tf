# Secrets Manager for Aurora master password
resource "aws_secretsmanager_secret" "aurora_password" {
  name_prefix             = "poc-bluegreen-aurora-password-"
  description             = "Aurora master password for POC Blue/Green"
  recovery_window_in_days = 7

  tags = {
    Name = "poc-bluegreen-aurora-password"
  }
}

resource "aws_secretsmanager_secret_version" "aurora_password" {
  secret_id = aws_secretsmanager_secret.aurora_password.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.aurora_password.result
  })
}

resource "random_password" "aurora_password" {
  length  = 32
  special = true
  override_special   = "!#$%&*()-_=+[]{}<>:?"
}

# RDS parameter group for Aurora PostgreSQL 14 - Cluster
resource "aws_rds_cluster_parameter_group" "aurora_pg14_cluster" {
  family      = "aurora-postgresql14"
  name        = "poc-aurora-pg-param-group-14-cluster"
  description = "Cluster parameter group for Aurora PostgreSQL 14 with logical replication"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "poc-aurora-pg-param-group-14-cluster"
  }
}

# RDS parameter group for Aurora PostgreSQL 14 - Instance
resource "aws_db_parameter_group" "aurora_pg14_instance" {
  family      = "aurora-postgresql14"
  name        = "poc-aurora-pg-param-group-14-instance"
  description = "Instance parameter group for Aurora PostgreSQL 14 with logical replication"

  tags = {
    Name = "poc-aurora-pg-param-group-14-instance"
  }
}

# RDS parameter group for Aurora PostgreSQL 15 - Cluster
resource "aws_rds_cluster_parameter_group" "aurora_pg15_cluster" {
  family      = "aurora-postgresql15"
  name        = "poc-aurora-pg-param-group-15-cluster"
  description = "Cluster parameter group for Aurora PostgreSQL 15 with logical replication"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "poc-aurora-pg-param-group-15-cluster"
  }
}

# RDS parameter group for Aurora PostgreSQL 15 - Instance
resource "aws_db_parameter_group" "aurora_pg15_instance" {
  family      = "aurora-postgresql15"
  name        = "poc-aurora-pg-param-group-15-instance"
  description = "Instance parameter group for Aurora PostgreSQL 15 with logical replication"

  tags = {
    Name = "poc-aurora-pg-param-group-15-instance"
  }
}

# RDS parameter group for Aurora PostgreSQL 16 - Cluster
resource "aws_rds_cluster_parameter_group" "aurora_pg16_cluster" {
  family      = "aurora-postgresql16"
  name        = "poc-aurora-pg-param-group-16-cluster"
  description = "Cluster parameter group for Aurora PostgreSQL 16 with logical replication"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "poc-aurora-pg-param-group-16-cluster"
  }
}

# RDS parameter group for Aurora PostgreSQL 16 - Instance
resource "aws_db_parameter_group" "aurora_pg16_instance" {
  family      = "aurora-postgresql16"
  name        = "poc-aurora-pg-param-group-16-instance"
  description = "Instance parameter group for Aurora PostgreSQL 16 with logical replication"

  tags = {
    Name = "poc-aurora-pg-param-group-16-instance"
  }
}

# RDS cluster for Aurora PostgreSQL
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier              = var.db_cluster_identifier
  engine                          = "aurora-postgresql"
  engine_version                  = var.aurora_engine_version
  database_name                   = "poc_bluegreen"
  master_username                 = var.db_master_username
  master_password                 = random_password.aurora_password.result
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg15_cluster.name
  db_subnet_group_name            = var.rds_subnet_group

  storage_encrypted    = true
  kms_key_id           = aws_kms_key.aurora_key.arn

  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot        = true
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.db_cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enable_http_endpoint           = false
  enable_global_write_forwarding = false

  tags = {
    Name = var.db_cluster_identifier
  }

  depends_on = [
    aws_rds_cluster_parameter_group.aurora_pg15_cluster,
    aws_security_group.aurora_sg
  ]
}

# Aurora cluster instance
resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  instance_class          = var.aurora_instance_type
  engine                  = aws_rds_cluster.aurora_cluster.engine
  engine_version          = aws_rds_cluster.aurora_cluster.engine_version
  db_parameter_group_name = aws_db_parameter_group.aurora_pg15_instance.name
  publicly_accessible     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = aws_kms_key.aurora_key.arn

  monitoring_interval             = 1
  monitoring_role_arn             = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name = "${var.db_cluster_identifier}-instance-1"
  }

  depends_on = [
    aws_db_parameter_group.aurora_pg15_instance,
    aws_iam_role.rds_monitoring_role
  ]
}

# Secondary RDS cluster (poc-bluegreen-tf)
resource "aws_rds_cluster" "aurora_cluster_tf" {
  cluster_identifier              = "poc-bluegreen-tf"
  engine                          = "aurora-postgresql"
  engine_version                  = var.aurora_engine_version
  database_name                   = "poc_bluegreen"
  master_username                 = var.db_master_username
  master_password                 = random_password.aurora_password.result
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg15_cluster.name
  db_subnet_group_name            = var.rds_subnet_group

  storage_encrypted    = true
  kms_key_id           = aws_kms_key.aurora_key.arn

  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot        = true
  skip_final_snapshot          = false
  final_snapshot_identifier    = "poc-bluegreen-tf-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enable_http_endpoint           = false
  enable_global_write_forwarding = false

  tags = {
    Name = "poc-bluegreen-tf"
  }

  depends_on = [
    aws_rds_cluster_parameter_group.aurora_pg15_cluster,
    aws_security_group.aurora_sg
  ]
}

# Secondary Aurora cluster instance
resource "aws_rds_cluster_instance" "aurora_instance_tf" {
  identifier              = "poc-bluegreen-tf-instance-1"
  cluster_identifier      = aws_rds_cluster.aurora_cluster_tf.id
  instance_class          = var.aurora_instance_type
  engine                  = aws_rds_cluster.aurora_cluster_tf.engine
  engine_version          = aws_rds_cluster.aurora_cluster_tf.engine_version
  db_parameter_group_name = aws_db_parameter_group.aurora_pg15_instance.name
  publicly_accessible     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = aws_kms_key.aurora_key.arn

  monitoring_interval             = 1
  monitoring_role_arn             = aws_iam_role.rds_monitoring_role.arn

  tags = {
    Name = "poc-bluegreen-tf-instance-1"
  }

  depends_on = [
    aws_db_parameter_group.aurora_pg15_instance,
    aws_iam_role.rds_monitoring_role
  ]
}

# KMS key for encryption
resource "aws_kms_key" "aurora_key" {
  description             = "KMS key for Aurora encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "poc-bluegreen-aurora-key"
  }
}

resource "aws_kms_alias" "aurora_key" {
  name          = "alias/poc-bluegreen-aurora"
  target_key_id = aws_kms_key.aurora_key.key_id
}

# IAM role for RDS monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "poc-bluegreen-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "poc-bluegreen-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora_cluster.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora_cluster.reader_endpoint
}

output "aurora_cluster_tf_endpoint" {
  description = "Secondary Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora_cluster_tf.endpoint
}

output "aurora_cluster_tf_reader_endpoint" {
  description = "Secondary Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora_cluster_tf.reader_endpoint
}

output "aurora_database_name" {
  description = "Aurora database name"
  value       = aws_rds_cluster.aurora_cluster.database_name
}

output "secret_name" {
  description = "Aurora password secret name in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.aurora_password.name
}
