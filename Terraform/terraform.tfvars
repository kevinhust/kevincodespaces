group_name              = "Zombies"
region                  = "us-east-1"
vpc_cidr                = "10.1.0.0/16"

# Public Subnets
public_subnet_1_cidr    = "10.1.1.0/24"
public_subnet_2_cidr    = "10.1.2.0/24"
public_subnet_3_cidr    = "10.1.3.0/24"
public_subnet_4_cidr    = "10.1.4.0/24"

# Private Subnets
private_subnet_1_cidr   = "10.1.5.0/24"
private_subnet_2_cidr   = "10.1.6.0/24"

# Availability Zones
availability_zone_1     = "us-east-1a"
availability_zone_2     = "us-east-1b"
availability_zone_3     = "us-east-1c"
availability_zone_4     = "us-east-1d"

# EC2 Configuration
ami_id                  = "ami-0e731c8a588258d0d"  # Amazon Linux 2 AMI
instance_type           = "t2.micro"

# S3 Configuration
s3_bucket               = "zombies-acs730"    # Using the same bucket with different prefixes

# Auto Scaling Configuration
asg_min_size            = 1
asg_max_size            = 4
asg_desired_capacity    = 2