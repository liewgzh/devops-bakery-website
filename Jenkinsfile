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
                            terraform init -upgrade
                            terraform plan
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Copy Keys & Setup Inventory') {
            steps {
                sh '''
                    mv -f terraform/nodekey.pem ~/.ssh/nodekey.pem
                    chmod 400 ~/.ssh/nodekey.pem
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
