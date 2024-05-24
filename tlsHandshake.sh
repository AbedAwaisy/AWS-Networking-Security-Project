#!/bin/bash

# Check if server IP is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: bash tlsHandshake.sh <server-ip>"
    exit 1
fi

SERVER_IP=$1
SESSION_ID=""
MASTER_KEY=""
CERT_FILE="serverCert.pem"
CA_CERT="cert-ca-aws.pem"

# Step 1: Send Client Hello
echo "Sending Client Hello..."
RESPONSE=$(curl -s -X POST --data '{"version":"1.3", "ciphersSuites":["TLS_AES_128_GCM_SHA256","TLS_CHACHA20_POLY1305_SHA256"], "message":"Client Hello"}' http://$SERVER_IP:8080/clienthello -H "Content-Type: application/json")

# Extract session ID and server certificate
SESSION_ID=$(echo $RESPONSE | jq -r '.sessionID')
echo $RESPONSE | jq -r '.serverCert' > $CERT_FILE

echo "Received Session ID: $SESSION_ID"
echo "Server Certificate saved to $CERT_FILE"

# Step 2: Verify Server Certificate
echo "Verifying Server Certificate..."
openssl verify -CAfile $CA_CERT $CERT_FILE > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 5
fi

echo "Server Certificate is valid."

# Step 3: Master Key Exchange
echo "Generating and Sending Master Key..."
MASTER_KEY=$(openssl rand -base64 32)
echo $MASTER_KEY > master_key.txt
ENCRYPTED_KEY=$(openssl smime -encrypt -aes-256-cbc -in master_key.txt -outform DER $CERT_FILE | base64 -w 0)

EXCHANGE_RESPONSE=$(curl -s -X POST --data "{\"sessionID\":\"$SESSION_ID\", \"masterKey\":\"$ENCRYPTED_KEY\", \"sampleMessage\":\"Hi server, please encrypt me and send to client!\"}" http://$SERVER_IP:8080/keyexchange -H "Content-Type: application/json")

# Decrypt the sample message
ENCRYPTED_MESSAGE=$(echo $EXCHANGE_RESPONSE | jq -r '.encryptedSampleMessage' | base64 -d)
DECRYPTED_MESSAGE=$(echo $ENCRYPTED_MESSAGE | openssl enc -d -aes-256-cbc -pbkdf2 -k $MASTER_KEY)

if [ "$DECRYPTED_MESSAGE" != "Hi server, please encrypt me and send to client!" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

echo "Client-Server TLS handshake has been completed successfully."
