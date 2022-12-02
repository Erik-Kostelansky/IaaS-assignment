terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "ErikCompany"

    workspaces {
      name = "IaaS-assignment"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_default_subnet" "default_subnet" {
  availability_zone = "eu-central-1a"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "testKey"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_launch_template" "ubuntu_launch_template" {
  name_prefix   = "ubuntu_launch_template"
  image_id      = "ami-0caef02b518350c8b"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = filebase64("./userDataScript.sh")
}

resource "aws_autoscaling_group" "ubuntu_autoscaling_group" {
  name                = "ubuntu_autoscaling_group"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 2
  vpc_zone_identifier = [aws_default_subnet.default_subnet.id]
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]

  launch_template {
    id = aws_launch_template.ubuntu_launch_template.id
  }

  depends_on = [aws_lb_target_group.lb_tg]
}

resource "aws_autoscaling_schedule" "scale_down_group_at" {
  scheduled_action_name  = "scale_down_group_at"
  desired_capacity       = 1
  max_size               = 1
  start_time             = "2022-12-02T17:00:00Z"
  end_time               = "2022-12-03T07:00:00Z"
  recurrence             = "0 0 * * 1-5"
  autoscaling_group_name = aws_autoscaling_group.ubuntu_autoscaling_group.name
}

resource "aws_security_group" "web-sg" {
  name = "web-sg"
  ingress {
    from_port   = 31555
    to_port     = 31555
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  // connectivity to ubuntu mirrors is required to run `apt-get update` and `apt-get install apache2`
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lb" {
  name               = "lb"
  load_balancer_type = "network"
}

resource "aws_lb_target_group" "lb_tg" {
  name        = "lb-tg"
  port        = 31555
  protocol    = "TCP_UDP"
  target_type = "instance"
  vpc_id      = aws_default_subnet.default_subnet.vpc_id
}

resource "aws_lb_listener" "lg_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "TCP_UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}


output "load-balancer-address" {
  value = aws_lb.lb.dns_name
}

