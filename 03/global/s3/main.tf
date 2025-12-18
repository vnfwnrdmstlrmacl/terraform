####################################
# S3 버킷 생성
# DynamoDB 테이블 생성
####################################

provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "my_tfstate" {
  bucket = "ljy-0516"

  tags = {
    Name        = "ljy-0516"
  }
}