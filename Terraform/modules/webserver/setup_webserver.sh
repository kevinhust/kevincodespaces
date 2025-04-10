#!/bin/bash

# Parameters
WEBSERVER_ID=$1
GROUP_NAME=$2
S3_BUCKET=$3

# Update system packages
sudo yum update -y

# Install Apache and awscli
sudo yum install -y httpd awscli

# Start and enable Apache service
sudo systemctl start httpd
sudo systemctl enable httpd

# Download image from S3 based on webserver ID
aws s3 cp s3://${S3_BUCKET}/web-content/webserver${WEBSERVER_ID}.jpg /var/www/html/webserver${WEBSERVER_ID}.jpg

# Get hostname and IP address
HOSTNAME=$(hostname)
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Determine creation method
CREATED_BY="Terraform"

# Create index.html with hostname, IP, creation method, and image
cat <<EOT | sudo tee /var/www/html/index.html
<h1>Hello from Webserver ${WEBSERVER_ID}</h1>
<p>Team: ${GROUP_NAME}</p>
<p>Hostname: $HOSTNAME</p>
<p>IP Address: $IP</p>
<p>Created by $CREATED_BY</p>
<img src="/webserver${WEBSERVER_ID}.jpg" alt="Webserver ${WEBSERVER_ID} Image">
EOT