terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Security Group liberando HTTP (8080) e SSH (22)
resource "aws_security_group" "java_api_sg" {
  name        = "java-api-sg"
  description = "Security group para a API Java Spring Boot"

  ingress {
    description = "Acesso HTTP da API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Acesso SSH para administracao"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Saida irrestrita para downloads e atualizacoes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "java-api-sg"
    Environment = "Development"
  }
}

# 2. Instância EC2 (Ubuntu 22.04 LTS) com instalação do OpenJDK 17
resource "aws_instance" "java_app_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (us-east-1)
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.java_api_sg.id]

  # Script de inicialização automática da VM
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y openjdk-17-jdk maven
              EOF

  tags = {
    Name        = "Java-App-Server"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# 3. Outputs para visualização do IP público
output "instance_public_ip" {
  description = "IP publico da instancia EC2"
  value       = aws_instance.java_app_server.public_ip
}

output "api_endpoint" {
  description = "URL base de acesso a aplicacao"
  value       = "http://${aws_instance.java_app_server.public_ip}:8080"
}