data "aws_subnets" "selected" {
  filter {
    name   = "tag:Name"
    values = ["sample-vpc-public-us-west-2b"] 
  }
}

data "aws_vpc" "vpc_id" {
  filter {
    name   = "tag:Name"
    values = ["sample-vpc"]  # Replace with the actual tag value
  }
}

output "vpc_id" {
  value = data.aws_vpc.vpc_id.id
}
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "var.ec2_sample"

  instance_type          = "t2.micro"
  monitoring             = true
  vpc_security_group_ids = [module.sample_ec2_sg.security_group_id]
  subnet_id              = data.aws_subnets.selected.ids[0]

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

module "sample_ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "sample-ec2"
  description = "Security group for SSH"
  vpc_id      = data.aws_vpc.vpc_id.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
