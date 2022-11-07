provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "videostudios-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet-1a"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id


  tags = {
    Name = "My-internet-gateway"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

# Attach the internet gateway  to the VPC
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-routing-table"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "web" {
  name        = "flask-server-SG"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "flask-server-SG"
  }
}

resource "aws_security_group" "video-generator" {
  name        = "video-generator-SG"
  description = "Allow video-generator-SG inbound traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description     = "Video Generation"
    security_groups = [aws_security_group.web.id]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "video-generator-SG"
  }
}

