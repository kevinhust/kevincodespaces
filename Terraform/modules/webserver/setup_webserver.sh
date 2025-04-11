#!/bin/bash

# Enable debug mode
set -x

# Parameters are passed as environment variables
# WEBSERVER_ID, GROUP_NAME, and S3_BUCKET are set by the template

# Create log file
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting webserver setup..."

# Update system packages
echo "Updating system packages..."
sudo yum update -y
echo "System packages updated."

# Install Apache, awscli and SELinux tools
echo "Installing Apache, awscli and SELinux tools..."
sudo yum install -y httpd awscli policycoreutils-python-utils
echo "Packages installed."

# Configure SELinux
echo "Configuring SELinux..."
sudo setsebool -P httpd_can_network_connect 1
echo "SELinux configured."

# Start and enable Apache service
echo "Starting Apache service..."
sudo systemctl start httpd
sudo systemctl enable httpd
echo "Apache service started and enabled."

# Download image from S3 based on webserver ID
echo "Downloading image from S3..."
aws s3 cp s3://${S3_BUCKET}/web-content/webserver${WEBSERVER_ID}.jpg /var/www/html/webserver${WEBSERVER_ID}.jpg
sudo chown apache:apache /var/www/html/webserver${WEBSERVER_ID}.jpg
sudo restorecon -v /var/www/html/webserver${WEBSERVER_ID}.jpg
echo "Image downloaded and permissions set."

# Get hostname and IP address
echo "Getting instance metadata..."
HOSTNAME=$(hostname)
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "Instance metadata retrieved."

# Create index.html with hostname, IP, creation method, and image
echo "Creating index.html..."
cat <<EOT | sudo tee /var/www/html/index.html
<h1>Hello from Webserver ${WEBSERVER_ID}</h1>
<p>Team: ${GROUP_NAME}</p>
<p>Hostname: ${HOSTNAME}</p>
<p>IP Address: ${IP}</p>
<p>Created by Terraform</p>
<img src="/webserver${WEBSERVER_ID}.jpg" alt="Webserver ${WEBSERVER_ID} Image">
EOT
sudo chown apache:apache /var/www/html/index.html
sudo restorecon -v /var/www/html/index.html
echo "index.html created and permissions set."

# Check Apache configuration
echo "Checking Apache configuration..."
sudo httpd -t
echo "Apache configuration check complete."

# Check Apache logs
echo "Checking Apache logs..."
sudo tail -n 50 /var/log/httpd/error_log
sudo tail -n 50 /var/log/httpd/access_log
echo "Apache logs checked."

# Test Apache
echo "Testing Apache configuration..."
sudo systemctl status httpd
curl -v http://localhost/
echo "Setup complete."