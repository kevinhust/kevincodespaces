# AWS Infrastructure Project

## Overview
This project implements a scalable web application infrastructure on AWS using Terraform. The infrastructure includes a multi-tier architecture with public and private subnets, load balancing, auto-scaling, and secure access through a bastion host.

## Architecture
The infrastructure consists of:
- 4 public subnets across 4 availability zones
- 2 private subnets across 2 availability zones
- 1 Bastion host for secure access
- 4 public web servers
- 2 private web servers
- 1 Application Load Balancer
- 1 Auto Scaling Group
- 1 NAT Gateway for private subnet internet access
- 1 Internet Gateway for public subnet internet access

## Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- Terraform installed (version >= 1.0.0)
- SSH key pair (will be created during setup)

## Project Structure

```
.
├── Terraform/           # Terraform configuration files
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Variable definitions
│   ├── terraform.tfvars # Variable values
│   └── modules/        # Terraform modules
└── Ansible/            # Ansible configuration
    ├── hosts           # Inventory file
    └── configure_webservers.yml  # Webserver configuration playbook
```

## Installation
1. Clone the repository
2. Configure AWS credentials
3. Initialize Terraform:
   ```bash
   cd Terraform
   terraform init
   ```
4. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

## Security Notes
- Keep the SSH private key secure
- Regularly rotate SSH keys
- Monitor security groups and IAM policies
- Keep AMIs and software up to date
