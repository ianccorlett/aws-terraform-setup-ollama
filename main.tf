provider "aws" {
  region = "eu-west-1"
}

variable "my_ip_address" {
  description = "Your IP address for security group access"
  type        = string
}

resource "aws_security_group" "ollama_sg" {
  name        = "ollama-security-group"
  description = "Allow access to Ollama server"

  # Allow SSH from specified IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # Allow Ollama API from specified IP
  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ollama_ec2" {
  # Same Ubuntu AMI - no need to change
  ami           = "ami-03662efaffa29be2a"
  instance_type = "c6i.2xlarge"
  key_name      = "ollama-key"
  security_groups = [aws_security_group.ollama_sg.name]

  root_block_device {
    volume_size = 50
  }

  user_data = <<-EOF
#!/bin/bash

# Exit on any error
set -e

echo "Starting Ollama installation script..." >> /var/log/user-data.log 2>&1

# Update system packages
echo "Updating system packages..." >> /var/log/user-data.log 2>&1
apt-get update -y && apt-get upgrade -y >> /var/log/user-data.log 2>&1

# Install required dependencies
echo "Installing dependencies..." >> /var/log/user-data.log 2>&1
apt-get install -y curl wget >> /var/log/user-data.log 2>&1

# Install Ollama
echo "Installing Ollama..." >> /var/log/user-data.log 2>&1
curl -fsSL https://ollama.com/install.sh | sh >> /var/log/user-data.log 2>&1

# Wait for Ollama service to be fully up
echo "Waiting for Ollama service to start..." >> /var/log/user-data.log 2>&1
sleep 5

# Create systemd service to run Ollama at startup
echo "Creating systemd service for Ollama..." >> /var/log/user-data.log 2>&1
cat << 'INNEREOF' > /etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Restart=always
Environment="OLLAMA_HOST=0.0.0.0:11434"
User=ubuntu

[Install]
WantedBy=multi-user.target
INNEREOF

# Enable and restart the service
echo "Enabling and starting Ollama service..." >> /var/log/user-data.log 2>&1
systemctl daemon-reload >> /var/log/user-data.log 2>&1
systemctl enable ollama >> /var/log/user-data.log 2>&1
systemctl restart ollama >> /var/log/user-data.log 2>&1

# Wait for Ollama to be ready for pulling models
echo "Waiting for Ollama to be ready..." >> /var/log/user-data.log 2>&1
sleep 10

# Pull the smaller quantized Mistral model
echo "Pulling quantized Mistral model..." >> /var/log/user-data.log 2>&1
sudo -u ubuntu ollama pull mistral:7b-instruct-v0.2-q4_0 >> /var/log/user-data.log 2>&1

echo "Ollama installation and model setup completed" >> /var/log/user-data.log 2>&1
EOF

  tags = {
    Name = "Ollama-Server"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ollama_ec2.public_ip
}

output "ollama_url" {
  description = "URL to access Ollama API"
  value       = "http://${aws_instance.ollama_ec2.public_ip}:11434"
}
