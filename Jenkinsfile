pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Terraform Init/Apply') {
            steps {
                dir('terraform') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-credentials',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {
                        sh '''
                            terraform init -upgrade -input=false
                            terraform plan -input=false -out=tfplan
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Copy Keys & Setup Inventory') {
            steps {
                sh '''
                    mkdir -p ~/.ssh
                    mv -f terraform/nodekey.pem ~/.ssh/nodekey.pem
                    chmod 400 ~/.ssh/nodekey.pem
                '''
            }
        }

        stage('Zip Website Folder') {
            steps {
                sh '''
                    rm -f website.zip
                    zip -r website.zip website/
                '''
            }
        }
        
        stage('Ansible Deploy') {
            steps {
                sh '''
                    CONTROLLER_IP=$(terraform -chdir=terraform output -raw control_node_public_ip)
                    NODE2_IP=$(terraform -chdir=terraform output -raw node2_public_ip)

                    cat <<EOF > ansible/inventory
[web]
Ansible-Managed-Node-2 ansible_host=$NODE2_IP ansible_ssh_private_key_file=~/.ssh/nodekey.pem

[web:vars]
ansible_user=ubuntu
EOF

                    scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no website.zip ubuntu@$CONTROLLER_IP:~
                    scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/inventory ubuntu@$CONTROLLER_IP:~
                    scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/web-server.yml ubuntu@$CONTROLLER_IP:~
                    scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ansible/ansible.cfg ubuntu@$CONTROLLER_IP:~
                    scp -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ~/.ssh/nodekey.pem ubuntu@$CONTROLLER_IP:~

                    ssh -i ~/.ssh/nodekey.pem -o StrictHostKeyChecking=no ubuntu@$CONTROLLER_IP << 'EOF'
                      sudo apt update
                      sudo apt install -y software-properties-common
                      sudo add-apt-repository --yes --update ppa:ansible/ansible
                      sudo apt update
                      sudo apt install -y unzip ansible

                      mkdir -p ~/.ssh
                      mv -f ~/nodekey.pem ~/.ssh/nodekey.pem
                      chmod 400 ~/.ssh/nodekey.pem

                      unzip -o website.zip
                      ansible-playbook -i inventory web-server.yml
EOF
                '''
            }
        }

        stage('Test - Web Up') {
            steps {
                sh '''
                    NODE2_IP=$(terraform -chdir=terraform output -raw node2_public_ip)
                    if ssh -i /var/lib/jenkins/.ssh/nodekey.pem -o StrictHostKeyChecking=no ubuntu@$NODE2_IP pgrep -x apache2 > /dev/null; then
                        echo "✅ Apache2 process is running on $NODE2_IP"
                    else
                        echo "❌ Apache2 process is NOT running on $NODE2_IP"
                        exit 1
                    fi
                '''
            }
        }

        stage('Test - Site Reachable') {
            steps {
                sh '''
                    NODE2_IP=$(terraform -chdir=terraform output -raw node2_public_ip)
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$NODE2_IP)
                    if [ "$STATUS" -eq 200 ]; then
                        echo "✅ Website is reachable at http://$NODE2_IP (HTTP 200)"
                    else
                        echo "❌ Website is NOT reachable at http://$NODE2_IP (status: $STATUS)"
                        exit 1
                    fi
                '''
            }
        }

        stage('Test - Service Running') {
            steps {
                sh '''
                    NODE2_IP=$(terraform -chdir=terraform output -raw node2_public_ip)
                    if ssh -i /var/lib/jenkins/.ssh/nodekey.pem -o StrictHostKeyChecking=no ubuntu@$NODE2_IP systemctl is-active --quiet apache2; then
                        echo "✅ Apache2 service is active and running on $NODE2_IP"
                    else
                        echo "❌ Apache2 service is NOT running on $NODE2_IP"
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Website Deployed Successfully"
        }
        failure {
            echo "❌ Deployment Failed"
        }
    }
}
