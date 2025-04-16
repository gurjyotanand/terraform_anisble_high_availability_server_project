terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.94.1"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


#VPC
resource "aws_vpc" "pj1_main" {
  cidr_block = "10.0.0.0/16"
}

#INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.pj1_main.id
  tags = {
    Name="pj1-igw"
  }
}

#PUBLIC SUBNETS
resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.pj1_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
  }

resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.pj1_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
}

#ROUTE TABLES
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.pj1_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_1_rt_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_rt_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

#SECURITY GROUP
resource "aws_security_group" "pj1_sg" {
  name = "pj1-sg"
  vpc_id = aws_vpc.pj1_main.id

  ingress {
    description = "SSH ACCESS"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP ACCESS"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#APPLICATION LOAD BALANCER
resource "aws_lb" "pj1_web_alb" {
  name = "pj1-web-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [ aws_subnet.public_1.id, aws_subnet.public_2.id ]
  security_groups = [aws_security_group.pj1_sg.id]
}

resource "aws_lb_target_group" "pj1_tg" {
  name = "pj1-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.pj1_main.id
  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "pj1_listener" {
  load_balancer_arn = aws_lb.pj1_web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pj1_tg.arn
  }
}

#LAUNCH TEMPLATE
resource "aws_launch_template" "pj1_lt" {
  name_prefix = "pj1_server"
  image_id = "ami-0100e595e1cc1ff7f" 
  instance_type = "t2.micro"
  user_data = filebase64("user_data.sh")
  vpc_security_group_ids = [aws_security_group.pj1_sg.id]
}

#AUTO SCALING GROUP
resource "aws_autoscaling_group" "pj1_asg" {
  desired_capacity =  2
  max_size = 2
  min_size = 1
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  launch_template {
    id = aws_launch_template.pj1_lt.id
  }
  target_group_arns = [aws_lb_target_group.pj1_tg.arn]
  health_check_type = "ELB"
}