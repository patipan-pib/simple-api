pipeline {
    agent any

    environment {
        VM2_HOST = "10.162.209.192"
        VM3_HOST = "10.162.209.18"
        U2 = "Test"
        U3 = "Pre"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "SCM uses credential 'github_ssh' from job config"
            }
        }

        stage('Check bound keys (VM2 & VM3)') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2')]) {
                    sh "ssh -i $K2 -o StrictHostKeyChecking=no $U2@${VM2_HOST} 'echo CONNECTED_VM2 && hostname && whoami'"
                }
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3', keyFileVariable: 'K3')]) {
                    sh "ssh -i $K3 -o StrictHostKeyChecking=no $U3@${VM3_HOST} 'echo CONNECTED_VM3 && hostname && whoami'"
                }
            }
        }

        stage('Prepare Docker Registry on VM2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2')]) {
                    sh """
                    ssh -i $K2 -o StrictHostKeyChecking=no $U2@${VM2_HOST} 'set -e
                      if [ ! -f /etc/docker/daemon.json ] || ! grep -q \\"10.162.209.192:5000\\" /etc/docker/daemon.json; then
                        echo "{\\"insecure-registries\\":[\\"10.162.209.192:5000\\"]}" | sudo tee /etc/docker/daemon.json
                        sudo systemctl restart docker
                      fi
                      docker ps --format "{{.Names}}" | grep -q "^registry$" || \
                      docker run -d --restart=always -p 5000:5000 --name registry registry:2
                    '
                    """
                }
            }
        }

        stage('Build & Test on VM2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2')]) {
                    sh """
                    ssh -i $K2 -o StrictHostKeyChecking=no $U2@${VM2_HOST} 'set -e
                        rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci

                        echo ">>> Clone API repo"
                        git clone https://github.com/patipan-pib/simple-api.git simple-api
                        cd simple-api

                        echo ">>> Unit test (skip if script not found)"
                        if [ -x ./run_unit_test.sh ]; then ./run_unit_test.sh; else echo "skip unit test"; fi
                        
                        echo ">>> Build Docker image"
                        docker build -f app/Dockerfile -t 10.162.209.192:5000/simple-api:${BUILD_NUMBER} .

                        echo ">>> (Optional) Sanity run"
                        (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
                        docker run -d --name simple-api -p 8081:5000 10.162.209.192:5000/simple-api:${BUILD_NUMBER} || true

                        echo ">>> Robot test (skip if repo/tests not found)"
                        cd .. && git clone https://github.com/patipan-pib/simple-api-robot.git simple-api-robot || true
                        if [ -d simple-api-robot ]; then
                          cd simple-api-robot
                          if command -v robot >/dev/null 2>&1; then
                            robot -d results tests/ || (echo "Robot test failed" && exit 1)
                          else
                            echo "skip robot (robot not installed)"
                          fi
                        else
                          echo "skip robot (repo not found)"
                        fi

                        echo ">>> Push image to registry"
                        docker push 10.162.209.192:5000/simple-api:${BUILD_NUMBER}

                        echo ">>> Cleanup temp container"
                        docker rm -f simple-api || true
                    '
                    """
                }
            }
        }

        stage('Prepare VM3 for Insecure Registry') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3', keyFileVariable: 'K3')]) {
                    sh """
                    ssh -i $K3 -o StrictHostKeyChecking=no $U3@${VM3_HOST} 'set -e
                      if [ ! -f /etc/docker/daemon.json ] || ! grep -q \\"10.162.209.192:5000\\" /etc/docker/daemon.json; then
                        echo "{\\"insecure-registries\\":[\\"10.162.209.192:5000\\"]}" | sudo tee /etc/docker/daemon.json
                        sudo systemctl restart docker
                      fi
                    '
                    """
                }
            }
        }

        stage('Deploy & Load Test on VM3') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3', keyFileVariable: 'K3')]) {
                    sh """
                    ssh -i $K3 -o StrictHostKeyChecking=no $U3@${VM3_HOST} 'set -e
                        echo ">>> Stop old container"
                        (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true

                        echo ">>> Pull image from registry"
                        docker pull 10.162.209.192:5000/simple-api:${BUILD_NUMBER}

                        echo ">>> Run new container"
                        docker run -d --name simple-api -p 8080:5000 10.162.209.192:5000/simple-api:${BUILD_NUMBER}

                        echo ">>> Run load test (if script exists)"
                        if [ -x ./run_load_test.sh ]; then ./run_load_test.sh; else echo "skip load test"; fi
                    '
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished'
        }
    }
}
