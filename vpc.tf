provider "aws" {
  region = "us-east-1"
}

data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://ipinfo.io/json'"]
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

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "public-subnet-1b"
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
  cidr_block              = "192.168.101.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "private-subnet-1a"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.102.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

# Attach the internet gateway  to the VPC
resource "aws_route_table" "public-r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-routing-table"
  }
}

resource "aws_route_table" "private-r" {
  vpc_id = aws_vpc.main.id

}

resource "aws_route_table_association" "public-a1" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-r.id
}

resource "aws_route_table_association" "public-a2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-r.id
}

resource "aws_route_table_association" "private-a1" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-r.id
}

resource "aws_route_table_association" "private-a2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-r.id
}

resource "aws_security_group" "web" {
  name        = "flask-server-SG"
  vpc_id      = aws_vpc.main.id


  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [aws_security_group.web_lb.id]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.web_lb.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # output from get_ip.tf
    cidr_blocks = ["${data.external.myipaddr.result.ip}/32"]

  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "web_lb" {
  name = "fakevideostudios-web-lb"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # output from get_ip.tf
    cidr_blocks = ["${data.external.myipaddr.result.ip}/32"]

  }

  ingress {
    description = "flask web"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.main.id
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

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.myipaddr.result.ip}/32"]
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

resource "aws_db_subnet_group" "default" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private-subnet.id, aws_subnet.private-subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "db_instance" {
  description = "security-group--db-instance"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks     = ["0.0.0.0/0"]
    from_port       = 5432
    protocol        = "tcp"
    to_port         = 5432
    security_groups = [aws_security_group.web.id]
  }

  name = "security-group--db-instance"

  tags = {
    Env  = "production"
    Name = "security-group--db-instance"
  }

  vpc_id = aws_vpc.main.id
}
