terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}
  provider "aws" {
    # Configuration options 
    region = "us-east-1"
  }


  #VPC
data "aws_vpc" "def_vpc" {
  default = true
}

data "aws_subnets" "all_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.def_vpc.id]
  }
}

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


  #ALB Sec Group
  resource "aws_security_group" "alb_secgr" {
    name        = "wayne_alb_secgr"
    description = "SecGr for alb http-SSH"
    tags = {
    Name = "wayne_alb_secgr"
    }

    ingress {
      from_port   = 80
      protocol    = "tcp"
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      protocol    = "tcp"
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      protocol    = -1
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  #RDS Sec Group
  resource "aws_security_group" "RDSsecgr" {
    name        = "wayne_RDS_secgr"
    description = "SecGr for RDS RDS-SSH"

    ingress {
      from_port   = 3306
      protocol    = "tcp"
      to_port     = 3306
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      protocol    = "tcp"
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      protocol    = -1
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
    #RDS
  resource "aws_db_instance" "rds" {
    allocated_storage      = 10
    db_name                = "mydb"
    engine                 = "MySQL"
    engine_version         = "8.0.19"
    instance_class         = "db.t2.micro"
    username               = "wayne1"
    password               = "wayne12345678"
    skip_final_snapshot    = true
    vpc_security_group_ids = [aws_security_group.RDSsecgr.id]
  }



  # target group
  resource "aws_lb_target_group" "target_group" {
    health_check {
      interval            = 10
      path                = "/"
      protocol            = "HTTP"
      timeout             = 5
      healthy_threshold    = 5
      unhealthy_threshold = 2
    }
    name        = "waynetg"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = data.aws_vpc.def_vpc.id
  }

  # load balancer
  resource "aws_lb" "app_lb" {
    name               = "wayneALB"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb_secgr.id]
    subnets            = data.aws_subnets.all_subnets.ids
  }

  # Load balancer-listener
  resource "aws_lb_listener" "alb_listener" {
    load_balancer_arn = aws_lb.app_lb.arn
    port              = 80
    protocol          = "HTTP"
    default_action {
      target_group_arn = aws_lb_target_group.target_group.arn
      type             = "forward"
    }
  }

 # Launch Template
resource "aws_launch_template" "launch_template" {
  name_prefix   = "wayne_lt"
  image_id      = "ami-09d3b3274b6c5d4aa"
  instance_type = "t2.micro"
  key_name      = "key1"
  user_data     = filebase64("${path.module}/userdata.sh")
}

resource "aws_autoscaling_group" "auto_scaling_gr" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}
