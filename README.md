# Networking and Security Project

## Overview
This project sets up a standard public and private network structure in AWS, automates SSH connections and key rotations, and implements a simplified version of the TLS handshake. It demonstrates practical applications of networking and security concepts, including encrypted communications and secure server access in a cloud environment.

## Prerequisites
- **AWS Account**: You need an AWS account with permissions to create and manage EC2 instances, VPCs, Internet Gateways, and Route Tables.
- **Key Pairs**: SSH key pairs for secure access to EC2 instances.
- **Security Groups**: Proper security groups allowing specified traffic.
- **Software**: Relevant software on your local machine (ssh, scp, bash, ssh-keygen).

## Setup and Configuration
### 1. AWS Services Setup
#### Infrastructure Components
- **Virtual Private Cloud (VPC)**: Create a VPC with a CIDR block that encompasses both your public and private subnets.
- **Subnets**: Create two subnets within your VPC:
  - **Public Subnet**: A subnet with an associated route table that routes traffic to the Internet Gateway.
  - **Private Subnet**: A subnet without direct internet access.
- **Internet Gateway (IGW)**: Attach an Internet Gateway to your VPC to enable internet access for the public subnet.
- **Route Tables**:
  - **Public Route Table**: Routes traffic from the public subnet to the Internet Gateway.
  - **Private Route Table**: Routes traffic within the VPC.
- **Security Groups**:
  - **Public Security Group**: Allows inbound SSH traffic (port 22) from any IP address.
  - **Private Security Group**: Allows inbound SSH traffic (port 22) from the public subnet.

### 2. Bastion Host Usage
#### Purpose
The bastion host provides secure SSH access to instances in the private subnet that are not directly accessible from the internet.

#### Requirements
- Both the bastion host (public instance) and the target private instance must be running.
- The public instance must have a security group allowing SSH access from your local machine.
- The private instance must have a security group allowing SSH access from the public instance.

#### Usage
- **bastion_connect.sh**: Use this script to securely access private instances through the bastion host.
  ```bash
  # Example command to connect to a private instance via the bastion host
  ./bastion_connect.sh <bastion-ip> <private-ip>
  ```
- **Use Cases**:
  - **Connecting to the Private Instance**:
    ```bash
    export KEY_PATH=~/your_key.pem
    ./bastion_connect.sh 3.144.209.252 10.0.1.205
    ```
  - **Running Commands on the Private Instance**:
    ```bash
    ./bastion_connect.sh 3.144.209.252 10.0.1.205 "ls -l"
    ```

### 3. Key Rotation
#### Purpose
Regularly updates SSH keys to mitigate the risk of unauthorized access due to compromised keys.

#### Requirements
- The public instance must have SSH access to the private instance.

#### Usage
- **ssh_keys_rotation.sh**: Rotates the keys of the private instance.
  ```bash
  # Example command to rotate keys on the private instance
  ./ssh_keys_rotation.sh <private-instance-ip>
  ```

#### Example
```bash
export KEY_PATH=~/your_key.pem
./ssh_keys_rotation.sh 10.0.1.205
```
After running this script, you should be able to access the private instance using the new key specified in the output.

### 4. TLS Handshake Simulation
#### Purpose
Demonstrates how secure channels are established using TLS, emphasizing the practical application of asymmetric and symmetric encryption.

#### Setup
- Run the TLS server app on one public instance (under tls_webserver/).
- Run the TLS client script on another instance to initiate a handshake with the server.

#### Usage
- **tls_handshake.sh**: Simulates the TLS handshake process.
  ```bash
  # Example command to perform a TLS handshake
  ./tls_handshake.sh <server-ip>
  ```

## Running the Project
To start using this project, follow these steps:
1. **Set up the AWS environment** as described in the AWS Services Setup section.
2. **Ensure all scripts are on your local machine** and are executable (`chmod +x script_name.sh`).
3. **Use the scripts as needed** to perform tasks like accessing the private subnet or rotating keys.

## Conclusion
This project provides a hands-on approach to understanding key networking and security mechanisms in a cloud environment. By setting up and using these services, you can enhance your knowledge and skills in network management and security practices.