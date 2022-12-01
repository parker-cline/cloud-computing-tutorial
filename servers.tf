resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "videostudios-key"
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./videostudios-key.pem"
  }
}

resource "aws_launch_configuration" "web-server" {
  name_prefix     = "fakevideostudios-web-"
  image_id        = "ami-09d3b3274b6c5d4aa"
  instance_type   = "t2.micro"
  user_data       = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo amazon-linux-extras install php8.0 mariadb10.5
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo usermod -a -G apache ec2-user
    sudo chown -R ec2-user:apache /var/www
    sudo chmod 2775 /var/www
    find /var/www -type d -exec sudo chmod 2775 {} \;
    find /var/www -type f -exec sudo chmod 0664 {} \;
    cd /var/www/html
    sudo echo "Hello World" > index.html
  EOF
  security_groups = [aws_security_group.web.id]

  lifecycle {
    create_before_destroy = true
  }
  key_name = "videostudios-key"
}

resource "aws_autoscaling_group" "web-server" {
  name                 = "fakevideostudios-web"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  target_group_arns    = [aws_lb_target_group.web-server.arn]
  launch_configuration = aws_launch_configuration.web-server.name
  vpc_zone_identifier  = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]
}

resource "aws_lb" "web-server" {
  name               = "fake-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_lb.id]
  subnets            = [aws_subnet.public-subnet.id, aws_subnet.public-subnet-2.id]
}

resource "aws_lb_listener" "web-server" {
  load_balancer_arn = aws_lb.web-server.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-server.arn
  }
}

resource "aws_lb_target_group" "web-server" {
  name     = "fake-web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_autoscaling_attachment" "web-server" {
  autoscaling_group_name = aws_autoscaling_group.web-server.id
  lb_target_group_arn    = aws_lb_target_group.web-server.arn
}

resource "aws_launch_configuration" "video-generator" {
  name_prefix     = "fakevideostudios-generator-"
  image_id        = "ami-09d3b3274b6c5d4aa"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.video-generator.id]
  key_name        = "videostudios-key"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "video-generator" {
  name                 = "fakevideostudios-generator"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.video-generator.name
  vpc_zone_identifier  = [aws_subnet.private-subnet.id, aws_subnet.private-subnet-2.id]
}

