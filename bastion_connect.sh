#!/bin/bash

# Check if the KEY_PATH environment variable is set
if [ -z "$KEY_PATH" ]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

# Check if at least one argument (the public instance IP) is provided
if [ $# -lt 1 ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

# Extract the arguments
BASTION_IP=$1
PRIVATE_IP=$2
COMMAND=$3

# Define the path to the new key file on the bastion host
NEW_KEY_PATH_FILE="/home/ubuntu/new_key_path.pem"

# Check if the new key file exists on the bastion host
ssh -i "$KEY_PATH" ubuntu@$BASTION_IP "test -f $NEW_KEY_PATH_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to find the new key path file on the bastion host"
    exit 5
fi

# Function to connect to the public instance
connect_public() {
    ssh -t -i "$KEY_PATH" ubuntu@"$BASTION_IP"
}

# Function to connect to the private instance via the public instance
connect_private() {
    ssh -t -i "$KEY_PATH" ubuntu@"$BASTION_IP" "ssh -t -i $NEW_KEY_PATH_FILE ubuntu@$PRIVATE_IP"
}

# Function to run a command on the private instance via the public instance
run_command_private() {
    ssh -t -i "$KEY_PATH" ubuntu@"$BASTION_IP" "ssh -t -i $NEW_KEY_PATH_FILE ubuntu@$PRIVATE_IP '$COMMAND'"
}

# Determine which operation to perform
if [ -n "$PRIVATE_IP" ] && [ -n "$COMMAND" ]; then
    run_command_private
elif [ -n "$PRIVATE_IP" ]; then
    connect_private
else
    connect_public
fi
