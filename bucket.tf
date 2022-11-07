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
  route_table_id  = aws_route_table.r.id #to public subnet?
}