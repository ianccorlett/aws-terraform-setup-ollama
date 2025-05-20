# aws-terraform-setup-ollama

## Description
This repo enables setting up your private Ollama server with open-source LLMs. Uses tofu terraform script to setup ollama server in AWS EC2.

## Features
- private ollama server for you
- run any open source LLM eg llama3.5, deepseek etc
- select size of GPU you want to balance speed vs spend

## Installation

### SETUP OLLAMA SERVER ON EC2
To run the terraform script and setup ollama server: 
- set a local variable for my_ip_address: export TF_VAR_my_ip_address="<your_IP>"
- create a PEM file with your ollama key (see ollama website for details)
- now run command: tofu apply

### SWITCH OFF OLLAMA SERVER IF NOT USING!
- To destroy terraform server use: tofu destroy