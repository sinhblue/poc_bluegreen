variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-06bcde38007501e84"
}

variable "subnet_id" {
  description = "Subnet ID for EC2"
  type        = string
  default     = "subnet-0ef190560d1929b7e"
}

variable "rds_subnet_group" {
  description = "RDS subnet group name"
  type        = string
  default     = "default"
}

variable "db_master_username" {
  description = "Master username for RDS Aurora"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "my-key-pair"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "aurora_instance_type" {
  description = "Aurora instance type"
  type        = string
  default     = "db.r6g.large"
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "14.17"
}

variable "db_cluster_identifier" {
  description = "Aurora cluster identifier"
  type        = string
  default     = "poc-bluegreen"
}
