provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    terraform = "true"
    ManagedBy = "Terraform"
  }
}

data "aws_availability_zones" "availability_zones" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "main_vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "main_igw"
  })
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone       = data.aws_availability_zones.availability_zones.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name   = "public_subnet"
    Public = "true"
  })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    Name = "public_route_table"
  })
}

resource "aws_route_table_association" "public_rt_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_security_group" "public_security_group" {
  name        = "public security group"
  description = "Security Group that allows access to instances in Public subnet"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    Name = "public_security_group"
  })
}
resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh" {
  security_group_id = aws_security_group.public_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "public_allow_http" {
  security_group_id = aws_security_group.public_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "public_allow_all_traffic" {
  security_group_id = aws_security_group.public_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}
resource "aws_instance" "public_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = <<-EOF
    #! /bin/bash

    sudo yum update && sudo yum install docker -y
    sudo systemctl start docker.service && sudo systemctl enable docker.service
    sudo usermod -aG docker ec2-user
  EOF

  tags = merge(local.common_tags, {
    Name   = "public_instance"
    Public = "true"
  })
}

resource "aws_key_pair" "key_pair" {
  key_name   = "public_key_name"
  public_key = file(var.public_key_file)
}

resource "aws_ecr_repository" "flak" {
  name                 = "flask"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(local.common_tags, {
    Name = "flask"
  })
}

data "aws_iam_policy" "ecr_policy" {
  name = "EC2InstanceProfileForImageBuilderECRContainerBuilds"
}
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecr_role" {
  name               = "ECRRole"
  description        = "AWS Role used to attached to EC2 instance to give it the permission to login, push, and pull images in ECR repository"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}
resource "aws_iam_role_policy_attachment" "ecr_role_policy_attachment" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = data.aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_ecr_profile"
  role = aws_iam_role.ecr_role.name
}
