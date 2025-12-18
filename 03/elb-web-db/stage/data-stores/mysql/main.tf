#######################
# provider 설정
# DB(mysql) 인스턴스 생성
#######################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
  backend "s3"{
    bucket         = "ljy-0516"
    key            = "golobal/s3/terraform.tfstate"
    region         = "us-east-2"
    # dynamodb_table = "mylocktable"
    use_lockfile = true
  }
}


# provider 설정

provider "aws" {
  region = "us-east-2"
}


# DB(mysql) 인스턴스 생성
# *https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# username/password
# dbuser/dbpassword
# DB name
resource "aws_db_instance" "mydb" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.c6gd.medium"
  username             = "${var.dbuser}"
  password             = "${var.dbpassword}"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}