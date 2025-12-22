variable "subnet_id" {
  description = "VPC subnet_id"
  type = string
}

variable "instance_type"{
  
  default = "t3.micro"
}

variable "EC2_tags" {
  default = {
    Name = "example"
  }
}