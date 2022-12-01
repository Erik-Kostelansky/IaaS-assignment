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

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "testKey"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_instance" "web" {
  ami                    = "ami-0caef02b518350c8b"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  key_name               = aws_key_pair.generated_key.key_name

  tags = {
    Name = "Ubuntu-VM"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install nginx
              systemctl restart nginx
              EOF
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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web-address" {
  value = "${aws_instance.web.public_dns}"
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

