#!/bin/bash

# Set the path to the Terraform directory
TERRAFORM_DIR="Terraform"
KEY_FILE="${TERRAFORM_DIR}/zombie_key"

# Check if ANSIBLE_VAULT_PASSWORD is set
if [ -z "$ANSIBLE_VAULT_PASSWORD" ]; then
    echo "Error: ANSIBLE_VAULT_PASSWORD environment variable is not set"
    exit 1
fi

# Check if the private key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Private key file not found at $KEY_FILE"
    exit 1
fi

# Create temporary password file
echo "$ANSIBLE_VAULT_PASSWORD" > temp_password_file

# Encrypt the private key
ansible-vault encrypt --vault-password-file temp_password_file "$KEY_FILE"

# Remove temporary password file
rm temp_password_file

echo "Private key encrypted successfully" 