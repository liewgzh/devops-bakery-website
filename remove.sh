#!/bin/bash
set -e

echo "🔻 Destroying infrastructure..."

# Go to Terraform directory
cd terraform/

# Run Terraform destroy with auto-approve to avoid interactive prompt
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed."