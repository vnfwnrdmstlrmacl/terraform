############################
# provider 설정
# s3 버킷 생성
# dynamodb 테이블 생성 (LockID)
############################

# provider 설정
provider "aws" {
  region = "us-east-2"
}

# s3 버킷 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "mytfstate" {
  bucket = "ljy-0516"

  tags = {
    Name        = "mytfstate"
  }
}

#################################
# dynamodb 테이블 생성 (LockID)
# S3 버킷 ARN -> output
# dynamodb 테이블 이름
#################################
# resource "aws_dynamodb_table" "mylocktable" {
#   name           = "mylocktable"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "LockID"
  
#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "mylocktable"
#   }
# }