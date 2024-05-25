#!/bin/bash

# Ensure the script is executed with a server IP
if [ "$#" -ne 1 ]; then
    echo "Usage: bash tlsHandshake.sh <server-ip>"
    exit 1
fi

SERVER_IP=$1
SESSION_ID=""
MASTER_KEY=""
CERT_FILE="serverCert.pem"
CA_CERT="$HOME/cert-ca-aws.pem"
MASTER_KEY_FILE="master_key.txt"

# Check if jq and openssl are installed
if ! command -v jq &> /dev/null || ! command -v openssl &> /dev/null; then
    echo "jq and openssl are required. Please install them before running this script."
    exit 2
fi

# Step 1: Send Client Hello
echo "Sending Client Hello..."
RESPONSE=$(curl -sf -X POST --data '{"version":"1.3", "ciphersSuites":["TLS_AES_128_GCM_SHA256","TLS_CHACHA20_POLY1305_SHA256"], "message":"Client Hello"}' http://$SERVER_IP:8080/clienthello -H "Content-Type: application/json")
if [ $? -ne 0 ]; then
    echo "Failed to send Client Hello."
    exit 3
fi

# Extract session ID and server certificate
SESSION_ID=$(echo $RESPONSE | jq -r '.sessionID')
echo $RESPONSE | jq -r '.serverCert' > $CERT_FILE

if [ -z "$SESSION_ID" ] || [ ! -s "$CERT_FILE" ]; then
    echo "Failed to receive valid session ID or server certificate."
    exit 4
fi

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
MASTER_KEY=$(openssl rand -base64 32) # Generate 32 random bytes and encode them in base64
echo -n $MASTER_KEY > $MASTER_KEY_FILE

ENCRYPTED_KEY=$(openssl smime -encrypt -aes-256-cbc -in $MASTER_KEY_FILE -outform DER $CERT_FILE | base64 -w 0)
echo "Master Key: $MASTER_KEY"
echo "Encrypted Master Key: $ENCRYPTED_KEY"

EXCHANGE_RESPONSE=$(curl -sf -X POST --data "{\"sessionID\":\"$SESSION_ID\", \"masterKey\":\"$ENCRYPTED_KEY\", \"sampleMessage\":\"Hi server, please encrypt me and send to client!\"}" http://$SERVER_IP:8080/keyexchange -H "Content-Type: application/json")
if [ $? -ne 0 ]; then
    echo "Failed to send master key exchange request."
    exit 8
fi

# Decrypt the sample message
ENCRYPTED_MESSAGE=$(echo $EXCHANGE_RESPONSE | jq -r '.encryptedSampleMessage' | base64 -d)
if [ $? -ne 0 ]; then
    echo "Failed to decode base64 encrypted sample message."
    exit 9
fi

echo "Encrypted sample message: $ENCRYPTED_MESSAGE"
echo "Decrypting the sample message..."

# Decrypt the sample message
DECRYPTED_MESSAGE=$(echo "$ENCRYPTED_MESSAGE" | openssl enc -d -aes-256-cbc -pbkdf2 -k $MASTER_KEY)
if [ $? -ne 0 ]; then
    echo "Failed to decrypt the sample message."
    exit 6
fi

if [ "$DECRYPTED_MESSAGE" != "Hi server, please encrypt me and send to client!" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

echo "Client-Server TLS handshake has been completed successfully. Well Done! you've manually implemented a secure communication over HTTP! Thanks god we have TLS in real life :-)"
