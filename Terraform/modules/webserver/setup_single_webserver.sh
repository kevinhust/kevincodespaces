#!/bin/bash

# Enable debug mode
set -x

# Create log file
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting webserver setup..."

# Update system packages
echo "Updating system packages..."
sudo yum update -y
echo "System packages updated."

# Install Apache and awscli
echo "Installing Apache and awscli..."
sudo yum install -y httpd awscli
echo "Apache and awscli installed."

# Start and enable Apache service
echo "Starting Apache service..."
sudo systemctl start httpd
sudo systemctl enable httpd
echo "Apache service started and enabled."

# Download image from S3 based on webserver ID
echo "Downloading image from S3..."
aws s3 cp s3://${S3_BUCKET}/web-content/webserver${WEBSERVER_ID}.jpg /var/www/html/webserver${WEBSERVER_ID}.jpg
echo "Image downloaded."

# Set hostname
sudo hostnamectl set-hostname ${GROUP_NAME}-webserver-${WEBSERVER_ID}

# Get IP address
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Create index.html with hostname, IP, creation method, and image
echo "Creating index.html..."
cat <<EOT | sudo tee /var/www/html/index.html
<h1>Hello from Webserver ${WEBSERVER_ID}</h1>
<p>Team: ${GROUP_NAME}</p>
<p>Hostname: ${GROUP_NAME}-webserver-${WEBSERVER_ID}</p>
<p>IP Address: ${IP}</p>
<p>Created by Terraform</p>
<img src="/webserver${WEBSERVER_ID}.jpg" alt="Webserver ${WEBSERVER_ID} Image">
EOT
echo "index.html created."

# Test Apache
echo "Testing Apache configuration..."
sudo systemctl status httpd
curl -v http://localhost/
echo "Setup complete." 