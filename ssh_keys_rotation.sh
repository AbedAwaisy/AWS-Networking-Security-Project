#!/bin/bash

# Ensure the script is executed with a private instance IP
if [ $# -ne 1 ]; then
    echo "Usage: $0 <private-instance-ip>"
    exit 1
fi

PRIVATE_IP=$1
KEY_PATH="/home/ubuntu/new_key_path.pem"

# Check if the key file exists
if [ ! -f "$KEY_PATH" ]; then
    echo "The key file at KEY_PATH does not exist. Please check the path and try again."
    exit 2
fi

# Check if the key at KEY_PATH can connect to the private instance
echo "Testing if the key at KEY_PATH can connect to the private instance..."
if ! ssh -i "$KEY_PATH" -o "StrictHostKeyChecking=no" -o "BatchMode=yes" ubuntu@$PRIVATE_IP "exit"; then
    echo "The key at KEY_PATH cannot connect to the private instance. Check the key and its permissions."
    exit 3
fi

# Generate a new key pair
NEW_KEY_PATH="/home/ubuntu/new_key"

ssh-keygen -t rsa -b 4096 -f $NEW_KEY_PATH -N "" -C "key_rotation"

# Append the new public key to authorized_keys on the private instance
cat $NEW_KEY_PATH.pub | ssh -i "$KEY_PATH" ubuntu@$PRIVATE_IP "cat >> ~/.ssh/authorized_keys"

# Replace the old key with the new key in the KEY_PATH
sudo mv $NEW_KEY_PATH $KEY_PATH
sudo rm $NEW_KEY_PATH.pub

# Set correct permissions for the new key at KEY_PATH
sudo chmod 400 $KEY_PATH

echo "Key rotation complete. You can now connect with the new key using:"
echo "ssh -i $KEY_PATH ubuntu@$PRIVATE_IP"
