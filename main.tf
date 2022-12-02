terraform {
  # Use plugin to communicate with AWS API
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.45.0"
    }
  }
  required_version = ">= 1.1.0"

  # Which Terraform Cloud workspaces to use for the current working directory
  cloud {
    organization = "ErikCompany"

    workspaces {
      name = "IaaS-assignment"
    }
  }
}

# Local variables
locals {
  enviromentName   = "IaasAssignment"
  region           = "eu-central-1"
  availabilityZone = "eu-central-1a"
}

# Configuration for AWS provider
# use "eu-central-1" AWS region
provider "aws" {
  region = local.region
}

# Use default subnet in AWS availability zone to deploy infrastructure,
# create instances in "eu-central-1a" availability zone subnet
resource "aws_default_subnet" "default_subnet" {
  availability_zone = local.availabilityZone
}

# Private key used to login to the instances via SSH in AWS console
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Public key for the previously generated private key
resource "aws_key_pair" "generated_key" {
  key_name   = "${local.enviromentName}-testKey"
  public_key = tls_private_key.example.public_key_openssh
}

# launch template for deploying VMs in auto scaling group
resource "aws_launch_template" "ubuntu_launch_template" {
  name_prefix = "${local.enviromentName}-launch_template"
  # Image ID of AWS EC2 instance
  image_id      = "ami-0caef02b518350c8b"
  instance_type = "t2.micro"

  # Key that will be used to access the AWS EC2 instance via AWS console
  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = filebase64("./userDataScript.sh")
}


# Auto scaling group resource for instances
resource "aws_autoscaling_group" "ubuntu_autoscaling_group" {
  name                = "${local.enviromentName}-ubuntu_autoscaling_group"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 2
  vpc_zone_identifier = [aws_default_subnet.default_subnet.id]
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]

  launch_template {
    id      = aws_launch_template.ubuntu_launch_template.id
    version = "$Latest"
  }

  depends_on = [aws_lb_target_group.lb_tg]
}

# Schedule group to schedule down from 18:00 CET to 08:00 CET
resource "aws_autoscaling_schedule" "scale_down_group_at" {
  scheduled_action_name  = "${local.enviromentName}-scale_down_group_at"
  max_size               = -1
  min_size               = -1
  desired_capacity       = 1
  start_time             = "2022-12-02T18:00:00Z"
  end_time               = "2022-12-03T08:00:00Z"
  recurrence             = "0 0 * * 1-5"
  time_zone              = "Africa/Algiers"
  autoscaling_group_name = aws_autoscaling_group.ubuntu_autoscaling_group.name
}

resource "aws_security_group" "web-sg" {
  name = "${local.enviromentName}-web-sg"
  # Allow IP traffic with destination port 31555 to VMs
  ingress {
    from_port   = 31555
    to_port     = 31555
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere to VMs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic from VMs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create AWS network load balancer
resource "aws_lb" "lb" {
  name               = "${local.enviromentName}-lb"
  load_balancer_type = "network"
  subnets            = [aws_default_subnet.default_subnet.id]
}

# Forward all traffic received by load balancer (port 80) to VMs on port 31555
resource "aws_lb_target_group" "lb_tg" {
  name        = "${local.enviromentName}-lb-tg"
  port        = 31555
  protocol    = "TCP_UDP"
  target_type = "instance"
  vpc_id      = aws_default_subnet.default_subnet.vpc_id
}

# Add a listener to loadbalancer for requests on port 80
resource "aws_lb_listener" "lg_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "TCP_UDP"

  # Forward all traffic on port 80 to load balancer target group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

# Export public load balancer address
output "load-balancer-address" {
  value = aws_lb.lb.dns_name
}

