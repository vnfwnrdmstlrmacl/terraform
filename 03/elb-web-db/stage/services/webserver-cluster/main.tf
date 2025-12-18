###########################
# provider 설정
# ASG 구성
# ALB 구성
############################

############################
# provider 설정
# - terraform_remote_state
# - provider
############################
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
  # Configuration options
}


data "terraform_remote_state" "myremotestate" {
  backend = "s3"
  config = {
    bucket         = "ljy-0516"
    key            = "golobal/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "mylocktable"
    
  }
}


############################
# ASG 구성
# - default vpc, default subnets 사용
# - SG 생성
# - Launch Template 생성
# - TG 생성
# - ASG 생성
############################
data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 80/tcp
resource "aws_security_group" "myLTSG" {
  name        = "myLTSG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myLTSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow80" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}



data "aws_ami" "amazon2023"{
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon

}
resource "aws_launch_template" "myLT" {
  name = "myLT"
  image_id = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myLTSG.id]

  user_data = base64encode(templatefile("./userdata.sh",{
    dbaddress = data.terraform_remote_state.myremotestate.outputs.dbaddress,
    dbport    = data.terraform_remote_state.myremotestate.outputs.dbport,
    dbname    = data.terraform_remote_state.myremotestate.outputs.dbname
  }))
}


#TG
resource "aws_lb_target_group" "myALBTG" {
  name     = "myALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}


#ASG
#target_group_arn
#depends_on
resource "aws_autoscaling_group" "myASG" {
  name                      = "myASG"
    desired_capacity        = 2
  max_size                  = 2
  min_size                  = 2

  target_group_arns = [aws_lb_target_group.myALBTG.arn]
  depends_on = [aws_lb_target_group.myALBTG]

  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  vpc_zone_identifier       = data.aws_subnets.default.ids
  launch_template {
    id      = aws_launch_template.myLT.id
    version = "$Latest"
  }

  tag {
    key                 = "name"
    value               = "myASG"
    propagate_at_launch = true
  }
}



############################
# ALB 구성
# - SG - ALB
# - ALB 생성
# - ALB Listener 생성
# - ALB Listener Rule 생성
# SG - ALB를 위한 SG
# 80/tcp
############################

#ALB

resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myLTSG.id]
  subnets            = data.aws_subnets.default.ids
}

#LB Listener
resource "aws_lb_listener" "myALB-listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALBTG.arn
  }
}

#LB Listener Rule
resource "aws_lb_listener_rule" "myALB-listener-rule" {
  listener_arn = aws_lb_listener.myALB-listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALBTG.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}