terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Use the account's default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group: controls what traffic can reach our instance
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-devops-project-sg"
  description = "Allow SSH, HTTP, and k3s API access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App traffic"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "Kubernetes NodePort"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "Prometheus NodePort"
    from_port   = 30090
    to_port     = 30090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-devops-project-sg"
  }
}

# Register our public key with AWS so we can SSH in
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-project-key"
  public_key = file("~/.ssh/devops-project-key.pub")
}

# Find the latest Ubuntu 22.04 AMI (Amazon Machine Image) automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu's official publisher)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "k3s_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  tags = {
    Name = "k3s-devops-project-node"
  }
}

output "instance_public_ip" {
  value = aws_instance.k3s_node.public_ip
}
