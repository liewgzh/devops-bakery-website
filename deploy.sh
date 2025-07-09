#!/bin/bash
set -e

echo "🚀 Initializing and applying Terraform configuration..."

# Run Terraform commands
terraform -chdir=terraform init -upgrade
terraform -chdir=terraform plan
terraform -chdir=terraform apply -auto-approve

# Ensure key has correct permissions before use
mv -f terraform/nodekey.pem ~/.ssh/
chmod 400 ~/.ssh/nodekey.pem

# Fetch IPs from Terraform
CONTROLLER_IP=$(terraform -chdir=terraform output -raw control_node_public_ip)
NODE2_IP=$(terraform -chdir=terraform output -raw node2_public_ip)

# Build inventory file
cat << EOF > ansible/inventory
[web]
Ansible-Managed-Node-2 ansible_host=$NODE2_IP ansible_ssh_private_key_file=~/.ssh/nodekey.pem

[web:vars]
ansible_user=ubuntu
EOF

# SCP files to controller node
scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no website.zip ubuntu@$CONTROLLER_IP:~
scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/inventory ubuntu@$CONTROLLER_IP:~
scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/web-server.yml ubuntu@$CONTROLLER_IP:~
scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/ansible.cfg ubuntu@$CONTROLLER_IP:~
scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ~/.ssh/nodekey.pem ubuntu@$CONTROLLER_IP:~

# Run everything inside the controller node
ssh -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ubuntu@$CONTROLLER_IP << 'EOF'
  set -e
  sudo apt update
  sudo apt install -y unzip ansible

  mkdir -p ~/.ssh
  mv -f ~/nodekey.pem ~/.ssh/nodekey.pem
  chmod 400 ~/.ssh/nodekey.pem

  unzip -o website.zip
  ansible-playbook -i inventory web-server.yml
EOF

echo "✅ Deployment complete! Visit: http://$NODE2_IP"