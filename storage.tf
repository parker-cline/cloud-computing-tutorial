resource "aws_s3_bucket" "videos_bucket_fakevideostudios" {
  bucket = "videos-bucket-fakevideostudios"
}

resource "aws_s3_bucket_acl" "videos_bucket_acl" {
  bucket = aws_s3_bucket.videos_bucket_fakevideostudios.id
  acl    = "private"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
}

#associate route table with vpc endpoint
resource "aws_vpc_endpoint_route_table_association" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private-r.id 
}

resource "random_string" "video-studios-db-password" {
  length  = 32
  upper   = true
  numeric  = true
  special = false
}

resource "aws_db_instance" "relational_db" {
  identifier             = "relational-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.5"
  username               = "collectics"
  password               = "random_string.video-studios-db-password.result}"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.video-generator.id]
  skip_final_snapshot    = true
}
