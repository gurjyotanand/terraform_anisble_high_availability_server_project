terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.94.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "pj1_main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.pf1_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"  
  }

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.pf1_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_lb" "pf1_web_alb" {
  name = "pf1_web-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [ aws_subnet.public_1.id, aws_subnet.public_2.id ]
}

resource "aws_launch_template" "pj1_lt" {
  name_prefix = "pj1_server"
  image_id = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"
  user_data = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "pj1_asg" {
  desired_capacity =  2
  max_size = 2
  min_size = 1
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  launch_template {
    id = aws_launch_template.pj1_lt.id
  }
}
