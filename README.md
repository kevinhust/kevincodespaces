# Zombies Team - ACS730 Project

This is the final project for ACS730 course, completed by the Zombies team (Kevin, Shruti, and Maria). The project implements a two-tier web application on AWS, automated with Terraform and Ansible deployment.

## Team Members

- Kevin (GitHub: `kevinhust`)
- Shruti (GitHub: `Shrutii-30`)
- Maria (GitHub: `MariaVSoto`)

## Architecture

- **Infrastructure**:
  - VPC (CIDR: 10.1.0.0/16)
  - 4 public subnets and 2 private subnets
  - 6 EC2 instances (5 web servers, 1 SSH test VM)
  - Application Load Balancer (ALB)
  - Auto Scaling Group (ASG)
  - NAT Gateway

- **Security Groups**:
  - ALB Security Group: Allows HTTP (80) from internet
  - Web Security Group: Allows HTTP (80) from ALB, SSH (22) from Bastion
  - Bastion Security Group: Allows SSH (22) from trusted IPs
  - Private Security Group: Allows SSH (22) from Bastion, HTTP (80) from Web servers

- **Web Servers**:
  - Webserver 1: Public Subnet 1, in ALB/ASG
  - Webserver 2: Public Subnet 2, Bastion Host
  - Webserver 3: Public Subnet 3, in ALB/ASG
  - Webserver 4: Public Subnet 4, configured by Ansible
  - Webserver 5: Private Subnet 1, configured by Ansible
  - Webserver 6: Private Subnet 2, SSH test only

## Prerequisites

1. Create S3 bucket:
   ```bash
   aws s3 mb s3://thezombiesofacs730
   ```

2. Upload website images:
   ```bash
   aws s3 cp webserver1.jpg s3://thezombiesofacs730/web-content/
   aws s3 cp webserver2.jpg s3://thezombiesofacs730/web-content/
   aws s3 cp webserver3.jpg s3://thezombiesofacs730/web-content/
   aws s3 cp webserver4.jpg s3://thezombiesofacs730/web-content/
   aws s3 cp webserver5.jpg s3://thezombiesofacs730/web-content/
   ```

3. Create SSH key pair:
   ```bash
   ssh-keygen -t rsa -b 2048 -f zombieacs730
   chmod 400 zombieacs730
   ```

## Security Configuration

1. Update trusted IPs (Optional):
   Edit `Terraform/terraform.tfvars` to specify trusted IP ranges for SSH access:
   ```hcl
   trusted_ips = ["YOUR_IP/32", "OFFICE_NETWORK/24"]
   ```

2. Security Group Access:
   - Internet → ALB (HTTP 80)
   - ALB → Web Servers (HTTP 80)
   - Trusted IPs → Bastion (SSH 22)
   - Bastion → Web/Private Servers (SSH 22)
   - Web Servers → Private Servers (HTTP 80)

## Deployment Steps

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the deployment plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. Wait for deployment to complete, then access the ALB DNS name from the outputs.

## Cleanup

To remove all resources:

1. Destroy Terraform resources:
   ```bash
   terraform destroy
   ```

2. Delete S3 bucket:
   ```bash
   aws s3 rm s3://thezombiesofacs730 --recursive
   aws s3 rb s3://thezombiesofacs730
   ```

## Notes

- All resources are deployed in the us-east-1 region
- Using t2.small instance type
- ASG configuration: minimum 2 instances, maximum 4 instances
- Bastion host (Webserver 2) is used to access instances in private subnets
- Security groups are configured with least privilege access
- Default trusted IPs is set to 0.0.0.0/0 (all IPs) - should be restricted in production