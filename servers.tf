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

resource "aws_instance" "video-generator" {
  ami                         = "ami-09d3b3274b6c5d4aa"
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.private-subnet.id
  vpc_security_group_ids      = [aws_security_group.video-generator.id]


  tags = {
    Name = "video-generator"
  }
}
resource "aws_instance" "web" {
  ami                         = "ami-09d3b3274b6c5d4aa"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = "videostudios-key"


  tags = {
    Name = "web-server"
  }

}
