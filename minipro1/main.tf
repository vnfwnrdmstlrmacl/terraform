####################################
# 인프라 구성
# - VPC 생성
# - IGW 생성 및 연결
# - 서브넷 생성
# -- public 서브넷
# - Route Table 생성 및 연결
# EC2 생성
# - Security Group 생성
# - key pair 생성
# - EC2 인스턴스 생성
# -- User_data(docker CMD)
# 사용자 연결
####################################


####################################
# - VPC 생성
####################################
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

####################################
# - IGW 생성 및 연결
####################################
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}



####################################
# - 서브넷 생성
# - 공인ip 할당

# -- public 서브넷

####################################
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "myPubSN"
  }
}



####################################
# - Route Table 생성 및 연결
# myIGW -> default route
# myPubSN에 연결
####################################
resource "aws_route_table" "myPubRT"{
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

####################################
# - Security Group 생성 -> 전체허용
####################################
resource "aws_security_group" "mySG" {
  name        = "allow_tls"
  description = "Allow inbound and outbound all traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG_in_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "mySG_out_all" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

####################################
# - key pair 생성
####################################

resource "aws_key_pair" "myKeyPair" {
  key_name   = "myKeyPair"
  public_key = file("~/.ssh/mykeypair.pub")
}

####################################
# - EC2 인스턴스 생성
# 새로 생성한 public subnet(myPubSN)에 EC2 생성
# SG(mySG) 연결
# key pair(myKeyPair)지정
#
####################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.myPubSN.id
  vpc_security_group_ids = [aws_security_group.mySG.id]
  key_name      = aws_key_pair.myKeyPair.key_name
  user_data_replace_on_change = true
  user_data = filebase64("user_data.sh")

  provisioner "local-exec" {
    command = templatefile("make_config.sh",{
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/mykeypair"
    })
    interpreter = ["bash", "-c"]
  }

  tags = {
    Name = "myEC2"
  }
}
####################################
# -- User_data(docker CMD)
####################################


# 사용자 연결
####################################