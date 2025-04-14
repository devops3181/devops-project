provider "aws" {
  region = "us-west-2"
}

# Data sources
data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:Name"
    values = ["sample-vpc-private-us-west-2*"]  # Adjust filter as needed
  }
}

data "aws_vpc" "vpc_id" {
  filter {
    name   = "tag:Name"
    values = ["sample-vpc"]
  }
}

# Security group module
module "sample_rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sample-ec2"
  description = "Security group for RDS access"
  vpc_id      = data.aws_vpc.vpc_id.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

# RDS module
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "rds_name"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.small"
  allocated_storage = 5

  db_name  = "demodb"
  username = "user"
  port     = 3306

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [module.sample_rds_sg.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  monitoring_interval    = 30
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "user"
    Environment = "var.env"  # Use variable reference without quotes
  }

  # Subnet group
  create_db_subnet_group = true

  # Make sure you pass actual subnet IDs or use the data source to fetch them dynamically
  subnet_ids             = data.aws_subnets.private_subnets.ids

  family                = "mysql5.7"
  major_engine_version  = "5.7"
  deletion_protection   = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}


