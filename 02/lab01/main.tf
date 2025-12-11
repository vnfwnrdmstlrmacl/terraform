#############
# 1. provider
# 2. VPC
# 3. IGW
# 4. PubSN
# 5. pubSN-RT 
##############


################
# 1. terraform/provider
################
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
}



################
# 2. VPC
# * VPC 생성
# * dns 호스트 이름 활성화
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
#################


resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true # dns 호스트 이름 활성화

  tags = {
    Name = "myVPC"
  }
  
}

#################
# 3. IGW
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
#################
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

#################
# 4. PubSN
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
#PubSN 생성
# 공인 ip 활성화
#################
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # 공인 ip 활성화
  tags = {
    Name = "myPubSN"
  }
}
#################
# 5. pubSN-RT 
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# default route
# pubSN <- 연결 -> pubSN-RT
#################
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRTAssoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}
