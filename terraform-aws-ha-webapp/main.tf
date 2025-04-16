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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pj1_main.id
  tags = {
    Name="pj1-igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.pj1_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  }

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.pj1_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_lb" "pj1_web_alb" {
  name = "pj1-web-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [ aws_subnet.public_1.id, aws_subnet.public_2.id ]
}

resource "aws_launch_template" "pj1_lt" {
  name_prefix = "pj1_server"
  image_id = "ami-04985531f48a27ae7" 
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
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pj1_main.id
  route {
    cidr_block = "0.0.0.0/0"  # Route all traffic to IGW
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnets with the route table
resource "aws_route_table_association" "public_1_rt_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_rt_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}