# The Zombies of ACS730 - AWS Infrastructure Project

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

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/MariaVSoto/TheZombiesofACS730.git
   cd TheZombiesofACS730
   ```

2. Configure AWS credentials:
   ```bash
   aws configure
   ```

3. Initialize Terraform:
   ```bash
   cd Terraform
   terraform init
   ```

4. Update `terraform.tfvars` with your specific values:
   - Replace `ami_id` with your desired AMI ID
   - Set `bastion_ip` to your IP address
   - Configure `s3_bucket_name` for your S3 bucket

5. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

## Infrastructure Components

### Network
- VPC with CIDR block 10.1.0.0/16
- Public subnets (10.1.1.0/24 to 10.1.4.0/24)
- Private subnets (10.1.5.0/24 and 10.1.6.0/24)
- Internet Gateway for public subnet access
- NAT Gateway for private subnet internet access

### Security
- Security groups for web servers, bastion host, and private instances
- SSH access restricted to bastion host
- Bastion host access restricted to specified IP address
- IAM roles and policies for S3 access

### Compute
- EC2 instances for web servers and bastion host
- Auto Scaling Group for web servers
- Application Load Balancer for traffic distribution

### Storage
- S3 bucket for static content
- IAM roles for S3 access

## Accessing the Infrastructure
1. Connect to the bastion host:
   ```bash
   ssh -i zombie_key ec2-user@<bastion_public_ip>
   ```

2. From the bastion host, connect to private instances:
   ```bash
   ssh -i zombie_key ec2-user@<private_instance_ip>
   ```

## Maintenance
- Monitor the Auto Scaling Group through AWS Console
- Check ALB health checks for instance status
- Use CloudWatch for monitoring and logging

## Cleanup
To destroy the infrastructure:
```bash
terraform destroy
```

## Security Notes
- Keep the SSH private key secure
- Regularly rotate SSH keys
- Monitor security groups and IAM policies
- Keep AMIs and software up to date