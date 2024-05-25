#!/bin/bash

# Check if server IP is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: bash tlsHandshake.sh <server-ip>"
    exit 1
fi

SERVER_IP=$1

# Step 1 - Send Client Hello
echo "Sending Client Hello to the server..."
CLIENT_HELLO_RESPONSE=$(curl -s -X POST "http://$SERVER_IP:8080/clienthello" \
    -H "Content-Type: application/json" \
    -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}')

# Extracting session ID and server certificate
SESSION_ID=$(echo "$CLIENT_HELLO_RESPONSE" | jq -r '.sessionID')
SERVER_CERT=$(echo "$CLIENT_HELLO_RESPONSE" | jq -r '.serverCert')

# Step 2 - Verify server's certificate
echo "Storing server certificate..."
echo "$SERVER_CERT" > serverCert.pem

#  Download CA certificate
echo "Downloading CA certificate using wget..."
wget -q -O cert-ca-aws.pem https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem

if [ ! -f cert-ca-aws.pem ]; then
    echo "Failed to download CA certificate."
    exit 2
fi

echo "Storing server certificate..."
echo "$SERVER_CERT" > serverCert.pem

echo "Verifying server certificate..."
openssl verify -CAfile cert-ca-aws.pem serverCert.pem
if [ "$?" -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 5
fi

# Step 3 - Generate a 32-byte master key and encrypt it using the server's public key
echo "Generating master key..."
MASTER_KEY=$(openssl rand -base64 32)
echo "$MASTER_KEY" > masterKey.txt

echo "Encrypting master key..."
ENCRYPTED_MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in masterKey.txt -outform DER serverCert.pem | base64 -w 0)

# Step 4 - Send the encrypted master key to the server
echo "Exchanging keys with the server..."
KEY_EXCHANGE_RESPONSE=$(curl -s -X POST "http://$SERVER_IP:8080/keyexchange" \
    -H "Content-Type: application/json" \
    -d "{\"sessionID\": \"$SESSION_ID\", \"masterKey\": \"$ENCRYPTED_MASTER_KEY\", \"sampleMessage\": \"Hi server, please encrypt me and send to client!\"}")

# Extract encrypted sample message
ENCRYPTED_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE_RESPONSE" | jq -r '.encryptedSampleMessage')

# Decrypt the sample message
echo "Decrypting the sample message..."
DECRYPTED_MESSAGE=$(echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$MASTER_KEY")

# Verify decryption
if [ "$DECRYPTED_MESSAGE" != "Hi server, please encrypt me and send to client!" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

echo "Client-Server TLS handshake has been completed successfully"
