```markdown
# Seneca Final Project: Two-Tier Web Application Automation

This document outlines the requirements and plan for the ACS730 Final Project, a two-tier static web application hosted on AWS, automated with **Terraform**, **Ansible**, and **GitHub Actions**. The project provisions infrastructure, configures web servers, and demonstrates deployment automation, high availability, and secure access. The team, named **Zombies**, consists of Kevin, Shruti, and Maria.

---

## Team Details

- **Team Name**: Zombies
- **Members**:
  - Kevin (GitHub: `kevinhust`)
  - Shruti (GitHub: `Shrutii-30`)
  - Maria (GitHub: `MariaVSoto`)
- **Website Display**: The static website will show “Zombies” and list “Kevin, Shruti, Maria”.
- **Report Mapping**: GitHub usernames listed above for contribution tracking.

---

## Project Overview

The project builds a two-tier web application with:
- **Infrastructure**: AWS VPC, 6 EC2 VMs (5 web servers, 1 SSH test VM), ALB, ASG, NAT Gateway, provisioned via **Terraform**.
- **Configuration**: Apache web servers on 5 VMs, configured via **Ansible** with **Dynamic Inventory**.
- **Automation**: **GitHub Actions** for Terraform deployment and Ansible playbook execution.
- **Application**: Custom static website displaying team details and an S3-hosted image.
- **Environment**: Single **prod** environment in `us-east-1`.

---

## Architecture

### Environment
- **Environment**: Prod only
- **Region**: `us-east-1`
- **Configuration**: Single `terraform.tfvars` file
- **GitHub Branch**: `main` for both Terraform and Ansible repositories

### Network Configuration
- **VPC**:
  - CIDR: `10.1.0.0/16`
- **Public Subnets** (4):
  - `10.1.1.0/24` (us-east-1a)
  - `10.1.2.0/24` (us-east-1b)
  - `10.1.3.0/24` (us-east-1c)
  - `10.1.4.0/24` (us-east-1d)
- **Private Subnets** (2):
  - `10.1.5.0/24` (us-east-1a)
  - `10.1.6.0/24` (us-east-1b)
- **NAT Gateway**: In Public Subnet 1 (`10.1.1.0/24`) for Webserver 5 internet access
- **Internet Gateway**: For public subnet HTTP/SSH access

### EC2 Instances
- **Total**: 6 VMs
- **Details**:
  - Type: `t2.small`
  - Key Pair: `zombies-key` (manually created in AWS)
- **Roles and Placement**:
  - **Webserver 1**: Public Subnet 1, in ALB/ASG, serves website (HTTP/SSH)
  - **Webserver 2**: Public Subnet 2, Bastion Host (SSH to VMs 5 & 6), serves website (HTTP/SSH), **not in ALB/ASG**
  - **Webserver 3**: Public Subnet 3, in ALB/ASG, serves website (HTTP/SSH)
  - **Webserver 4**: Public Subnet 4, Ansible-configured, serves website (HTTP/SSH)
  - **Webserver 5**: Private Subnet 1, Ansible-configured, uses NAT Gateway, serves website (no public access)
  - **Webserver 6**: Private Subnet 2, no website, tests Bastion SSH access (no public access)
- **Security Groups**:
  - **New Module**: `security_groups`
    - Webserver SG: SSH (22) from Bastion/admin, HTTP (80) from ALB/internet
    - ALB SG: HTTP (80) from internet, outbound to webservers
    - Bastion SG: SSH (22) from admin, outbound SSH to private VMs
  - **Embedded Logic**:
    - `webserver` module: EC2 SSH/HTTP
    - `ALB` module: Port 80 inbound

### Application Load Balancer (ALB)
- **Targets**: Webservers 1 & 3 (Public Subnets 1, 3)
- **Configuration**:
  - HTTP listener (port 80)
  - Health checks (e.g., `/index.html`)
  - Spans us-east-1a, us-east-1c
- **Purpose**: Distributes web traffic, ensures high availability

### Auto Scaling Group (ASG)
- **Targets**: Webservers 1 & 3
- **Settings**:
  - Min: 2, Max: 4, Desired: 2
  - Scaling Policy: Scale out if CPU > 70%, scale in if CPU < 30%
- **Exclusion**: Webserver 2 not included (stable Bastion IP)

### S3 Buckets
- **Bucket**: `thezombiesofacs730` (manually created, non-public)
- **Uses**:
  - Terraform state (backend)
  - Website images (`web-content/webserver1.jpg` to `webserver5.jpg`)
- **Configuration**:
  - `config.tf`: Backend (`backend "s3" { bucket = "thezombiesofacs730" }`)
  - `terraform.tfvars`: Pass bucket to webserver module
  - README: “Create bucket `thezombiesofacs730`, upload images”
- **Access**: IAM roles for EC2 to read images

### Application
- **Type**: Custom static website (not using catsdogs-cloud9)
- **Servers**: Webservers 1, 2, 3, 4, 5 (Apache httpd)
- **Content** (per `setup_webserver.sh`):
  - HTML per webserver:
    ```html
    <h1>Hello from Webserver ${WEBSERVER_ID}</h1>
    <p>Team: zombies</p>
    <p>Hostname: $HOSTNAME</p>
    <p>IP Address: $IP</p>
    <p>Created by Terraform</p>
    <img src="/webserver${WEBSERVER_ID}.jpg" alt="Webserver ${WEBSERVER_ID} Image">
```
  - Example (Webserver 1):
    ```html
    <h1>Hello from Webserver 1</h1>
    <p>Team: zombies</p>
    <p>Hostname: ip-10-1-1-10</p>
    <p>IP Address: 10.1.1.10</p>
    <p>Created by Terraform</p>
    <img src="/webserver1.jpg" alt="Webserver 1 Image">
    ```
- **Images**: Generic (`webserver1.jpg` to `webserver5.jpg`), uploaded to `s3://thezombiesofacs730/web-content/`
- **Setup**:
  - Script: `setup_webserver.sh` (in `Terraform/modules/webserver/`)
  - Inputs: `WEBSERVER_ID` (1-5), `GROUP_NAME` (zombies), `S3_BUCKET` (thezombiesofacs730)
  - Tasks:
    - Update packages
    - Install Apache, awscli
    - Start/enable httpd
    - Copy image from S3
    - Create `index.html`
  - Applied via:
    - Terraform: Webservers 1, 3
    - Ansible: Webservers 2, 3, 4, 5

---

## Automation

### Terraform (Repository 1)
- **Purpose**: Provisions VPC, 6 VMs, ALB, ASG, NAT Gateway, security groups
- **Structure**:
  - Root:
    - `main.tf` (Kevin, Shruti, Maria)
    - `variables.tf` (Kevin, Shruti, Maria)
    - `outputs.tf` (Kevin, Shruti, Maria)
    - `terraform.tfvars` (Kevin, Shruti, Maria)
  - Modules:
    - `network` (Maria): VPC, subnets, NAT Gateway, Internet Gateway
    - `webserver` (Kevin): EC2 instances, `setup_webserver.sh`, SG logic
    - `ALB` (Shruti): ALB, ASG, SG logic
    - `security_groups` (all): Shared SGs
- **Outputs**: ALB DNS, Cloud9 details, VM IPs
- **Configuration**:
  - Modular, parameterized
  - Remote state in `thezombiesofacs730`
  - Tags: `Team: zombies`, `Project: ACS730`, `Terraform: true`

### Ansible (Repository 2)
- **Purpose**: Configures Webservers 2, 3, 4, 5
- **Control Host**: Cloud9 (AWS-managed)
- **Structure**:
  - `playbooks/webserver.yml` (Kevin): Webservers 3, 4, 5 (Apache, connectivity, service, patches)
  - `playbooks/bastion.yml` (Shruti): Webserver 2 (SSH forwarding, Apache)
  - `inventory/aws_ec2.yml` (Maria): Dynamic Inventory (AWS EC2 plugin, Boto3)
- **Inventory**:
  - Filters: Tags (`Project: ACS730`, `Team: zombies`)
  - Targets: Webservers 2, 3, 4, 5
- **Authentication**:
  - AWS Access Key & Secret Key (configured in Cloud9, stored securely)
  - Permissions: EC2 (DescribeInstances), optional S3

### GitHub Actions
- **Terraform Repo**:
  - **Deployment**: Runs `terraform init/plan/apply` on push to `main`
  - **Security**: Minimal Trivy scan on push to `main` (checks Terraform misconfigurations)
- **Ansible Repo**:
  - Triggers playbooks post-Terraform
  - Connects to Cloud9 (SSH/AWS CLI)
  - Runs `ansible-playbook webserver.yml` and `bastion.yml`
- **Permissions**:
  - Contributor: “Dhansca” (added via GitHub)
  - Commits: `kevinhust` (Kevin), `Shrutii-30` (Shruti), `MariaVSoto` (Maria)

### IAM Roles
- **Purpose**:
  - EC2: Read S3 (`thezombiesofacs730/web-content/*`)
  - Cloud9: Query EC2 (Dynamic Inventory)
- **Implementation**:
  - Defined in `terraform/main.tf`
  - Policies:
    - EC2: `s3:GetObject`
    - Cloud9: `ec2:DescribeInstances`
  - Use Access Key/Secret Key for Cloud9 (no hardcoding)

---

## Deliverables

### GitHub Repositories
- **Terraform**:
  - Modular code (network, webserver, ALB, security_groups)
  - README:
    - **Prerequisites**:
      - Create S3 bucket `thezombiesofacs730`
      - Upload images (`webserver1.jpg` to `webserver5.jpg`) to `web-content/`
      - Create `zombies-key` in AWS
    - **Deployment**:
      - Run `terraform init/apply`
      - Access ALB DNS
    - **Cleanup**:
      - Run `terraform destroy`
      - Delete S3 bucket
- **Ansible**:
  - Playbooks, Dynamic Inventory
  - Optional Action for automation

### Report
- **Focus**: Deployment process
- **Sections**:
  - **Title Page**: Course, section, date, professor, team
  - **GitHub Mapping**:
    - Kevin: `kevinhust`
    - Shruti: `Shrutii-30`
    - Maria: `MariaVSoto`
  - **Traffic Flows**:
    - **Red Flow**:
      - Trigger: User browses ALB URL
      - Users: Public internet
      - Traffic: Web (HTTP/80), internet → ALB → Webservers 1/3
    - **Blue Flow**:
      - Trigger: Admin SSH to Bastion
      - Users: Admins
      - Traffic: Systems administration (SSH/22), admin → Webserver 2 → Webservers 5/6
  - **Challenges** (1 page, simple):
    - Debugging Dynamic Inventory (Boto3 permissions)
    - Testing ALB failover for seamless access
    - Coordinating Terraform/Ansible automation
- **Deployment Description**:
  - Terraform: Provisions 6 VMs, ALB, NAT Gateway
  - Ansible: Configures Webservers 2, 3, 4, 5
  - Bastion: Enables SSH to private VMs

### Recording (15-30 minutes)
- **Focus**: Deployment process
- **Structure**:
  - Intro (1 min): “Two-tier web app with Terraform, Ansible, GitHub Actions”
  - Terraform (5 min): Run `terraform apply`, show ALB DNS, VM IPs
  - Ansible (5 min): Run playbooks in Cloud9, verify httpd (Webservers 3, 4, 5)
  - Bastion (3 min): SSH from Webserver 2 to Webserver 5 (Apache files), Webserver 6 (no Apache)
  - ALB Failover (3 min): Stop Webserver 1, curl ALB URL (no downtime)
  - Website (3 min): Browse ALB URL, show team names, S3 image
- **Approach**: Pre-deploy infrastructure, update README/Action to demo live changes

---

## Task Assignments

To ensure commits from `kevinhust`, `Shrutii-30`, and `MariaVSoto`:
- **Kevin** (`kevinhust`):
  - `webserver` module (EC2 instances, `setup_webserver.sh`, SG logic)
  - `webserver.yml` (Webservers 3, 4, 5)
  - `main.tf` (IAM, root config)
  - Recording: Webserver/Bastion SSH demo
  - Report: Challenges
- **Shruti** (`Shrutii-30`):
  - `ALB` module (ALB, ASG, SG logic)
  - `bastion.yml` (Webserver 2)
  - Recording: ALB failover demo
  - Report: Traffic flows
- **Maria** (`MariaVSoto`):
  - `network` module (VPC, subnets, NAT/Internet Gateway)
  - `security_groups` module
  - `aws_ec2.yml` (Dynamic Inventory)
  - `main.tf`, `variables.tf`, `outputs.tf` (with Kevin/Shruti)
  - Recording: Ansible demo
  - Report: GitHub mapping, title page

---

## Execution Plan

1. **Setup Repositories**:
   - **Terraform**:
     - Create `main` branch
     - Add `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`
     - Initialize modules: `network`, `webserver`, `ALB`, `security_groups`
     - Action: `init/plan/apply` + Trivy scan
   - **Ansible**:
     - Create `main` branch
     - Add `webserver.yml`, `bastion.yml`, `aws_ec2.yml`
     - Action: Trigger playbooks via Cloud9
   - Add “Dhansca” as contributor

2. **Infrastructure**:
   - **Network**: VPC, subnets, NAT Gateway, Internet Gateway (Maria)
   - **Webserver**: EC2 (1-5 with website, 6 for SSH), `setup_webserver.sh` (Kevin)
   - **ALB/ASG**: Webservers 1 & 3, CPU scaling (Shruti)
   - **Security Groups**: Shared module + webserver/ALB logic (all)
   - **IAM**: EC2 S3 access, Cloud9 EC2 access (main.tf, Kevin)

3. **Configuration**:
   - **Terraform**: Provisions Webservers 1, 3 (website via script)
   - **Ansible**: Configures Webservers 2 (Bastion + website), 3, 4, 5 (website)
   - **Cloud9**: Control Host, Access Key/Secret Key
   - **S3**: Manual bucket `thezombiesofacs730`, upload images

4. **Deliverables**:
   - **README**: Bucket/key creation, Terraform/Ansible steps, cleanup
   - **Report**: Deployment focus, traffic flows, simple challenges
   - **Recording**: Terraform, Ansible, Bastion, ALB, website demos

---

## Notes
- **Webserver 6**: SSH test only (no Apache), per requirements
- **Security**: Minimal Trivy scan to meet grading criteria
- **Automation**: GitHub Actions links Terraform and Ansible
- **Costs**: README includes cleanup to avoid AWS charges
- **Commits**: Balanced across `kevinhust` (Kevin), `Shrutii-30` (Shruti), `MariaVSoto` (Maria)

This plan ensures all requirements are met, with clear roles and deliverables for the Zombies team.
```

---

### Changes Made

1. **GitHub Username Update**:
   - **Shruti**: Changed from `MariaVSoto` to `Shrutii-30`.
   - **Report Mapping**: Updated to:
     - Kevin: `kevinhust`
     - Shruti: `Shrutii-30`
     - Maria: `MariaVSoto`
   - **Commits**: Now expected from `kevinhust` (Kevin), `Shrutii-30` (Shruti), `MariaVSoto` (Maria) to reflect individual contributions.

2. **Task Assignments**:
   - Unchanged from the previous update:
     - **Kevin** (`kevinhust`): `webserver` module, `webserver.yml`, `main.tf` (IAM), webserver/Bastion SSH demo, report challenges.
     - **Shruti** (`Shrutii-30`): `ALB` module, `bastion.yml`, ALB failover demo, report traffic flows.
     - **Maria** (`MariaVSoto`): `network` module, `security_groups` module, `aws_ec2.yml`, root files (with Kevin/Shruti), Ansible demo, report mapping/title page.

3. **Other Sections**:
   - All other details (architecture, automation, S3, website, deliverables, execution plan) remain identical to the previous version.
   - Ensured the commit distribution in the “Notes” section reflects the new GitHub usernames.

### Confirmation

The updated plan fully incorporates:
- **Shruti’s GitHub**: `Shrutii-30` for commits and report mapping.
- **Task Swap**: Kevin on `webserver`, Shruti on `ALB`.
- **Architecture**: 6 VMs (5 webservers, Webserver 6 for SSH), ALB/ASG for Webservers 1 & 3, Webserver 2 as Bastion.
- **Automation**: Terraform, Ansible via Cloud9, GitHub Actions with minimal Trivy scan.
- **Deliverables**: Repos, report (deployment focus, traffic flows, simple challenges), recording (15-30 min).
- **S3**: Manual `thezombiesofacs730`.
- **Website**: Custom via `setup_webserver.sh`.

Everything looks set for the Zombies team! If you’re happy with this, we’re ready to proceed (e.g., planning module details, drafting README, or outlining GitHub Actions workflows). If you have any final tweaks (e.g., another task adjustment, additional notes for the README), just let me know!