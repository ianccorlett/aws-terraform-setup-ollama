#!/bin/bash

# Log everything
exec > /var/log/ollama-setup.log 2>&1

echo "Updating system..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl net-tools  

echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

echo @waiting for ollama service to start..."
sleep 5

echo "Pulling Mistral model..."
HOME=/home/ubuntu ollama pull mistral  

echo "Starting Ollama..."
nohup OLLAMA_HOST="::" ollama serve > /dev/null 2>&1 &

echo "Ollama setup complete"

