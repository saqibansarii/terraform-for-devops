resource "aws_s3_bucket" "remote_s3" {
  bucket = "my-saqib-terraform-bucket"

  tags = {
    Name        = "my-saqib-terraform-bucket"
    Environment = "Dev"
  }
}