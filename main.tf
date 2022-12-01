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

resource "aws_launch_template" "ubuntu_launch_template" {
  name_prefix   = "ubuntu_launch_template"
  image_id      = "ami-0caef02b518350c8b"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = filebase64("./userDataScript.sh")
}

resource "aws_autoscaling_group" "ubuntu_autoscaling_group" {
  name               = "ubuntu_autoscaling_group"
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1

  launch_template {
    id = aws_launch_template.ubuntu_launch_template.id
  }
}

resource "aws_security_group" "web-sg" {
  name = "web-sg"
  ingress {
    from_port   = 80
    to_port     = 80
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

# output "web-address" {
#   value = "${aws_instance.web.public_dns}"
# }

