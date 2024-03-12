terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_iam_policy" "my_policy" {
  name        = "my-policy"
  description = "My IAM policy"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "ec2:DescribeInstances",
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = "ec2:StartInstances",
        Resource  = "*"
      },
      {
        Effect    = "Allow",
        Action    = "ec2:StopInstances",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role" "my_role" {
  name               = "my-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "my_attachment" {
  name       = "my-attachment"
  roles      = [aws_iam_role.my_role.name]
  policy_arn = aws_iam_policy.my_policy.arn
}

resource "aws_security_group" "lab6_sg" {
  name        = "lab6_sg"
  description = "Remote SSH"
  vpc_id      = aws_vpc.lab6_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "lab6_vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "lab6_subnet" {
  vpc_id     = aws_vpc.lab6_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "lab6_igw" {
  vpc_id = aws_vpc.lab6_vpc.id
}

resource "aws_route_table" "lab6_rt" {
  vpc_id = aws_vpc.lab6_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab6_igw.id
  }
}

resource "aws_route_table_association" "lab6_rt_asso" {
  subnet_id      = aws_subnet.lab6_subnet.id
  route_table_id = aws_route_table.lab6_rt.id
}

resource "aws_instance" "lab6_security" {
  ami           = "ami-0f403e3180720dd7e"
  instance_type = "t2.micro"
  subnet_id      = aws_subnet.lab6_subnet.id  
  tags = {
    Name        = "Lab6-ec2"
    Owner       = "Vinay"
  }
  iam_instance_profile = aws_iam_instance_profile.my_profile.name
}

resource "aws_iam_instance_profile" "my_profile" {
  name = "my_profile"
  role = aws_iam_role.my_role.name
}

