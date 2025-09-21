pipeline {
    agent any

    environment {
        VM2 = "Test@10.162.209.192"   // VM2: Build & Test
        VM3 = "Pre@10.162.209.18"     // VM3: Deploy & Pre-prod
        REPO_API   = "git@github.com:patipan-pib/simple-api.git"
        REPO_ROBOT = "git@github.com:patipan-pib/simple-api-robot.git"
        REGISTRY   = "10.162.209.192:5000/simple-api"   // ใช้ Private Registry บน VM2 (port 5000)
    }

    stages {
        stage('Build & Test on VM2') {
            steps {
                sshagent (credentials: ['vm_ssh']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $VM2 '
                        set -e
                        rm -rf ~/ci && mkdir ~/ci && cd ~/ci

                        echo ">>> Clone API repo"
                        git clone ${REPO_API} simple-api
                        cd simple-api

                        echo ">>> Run unit tests"
                        ./run_unit_test.sh || exit 1

                        echo ">>> Build Docker image"
                        docker build -t ${REGISTRY}:\${BUILD_NUMBER} .

                        echo ">>> Run Robot test"
                        cd .. && git clone ${REPO_ROBOT}
                        cd simple-api-robot && robot -d results tests/

                        echo ">>> Push image to registry"
                        docker push ${REGISTRY}:\${BUILD_NUMBER}
                    '
                    """
                }
            }
        }

        stage('Deploy & Load Test on VM3') {
            steps {
                sshagent (credentials: ['vm_ssh']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $VM3 '
                        set -e
                        echo ">>> Pull image from registry"
                        docker pull ${REGISTRY}:\${BUILD_NUMBER}

                        echo ">>> Restart container"
                        docker stop simple-api || true
                        docker rm simple-api || true
                        docker run -d --name simple-api -p 80:8080 ${REGISTRY}:\${BUILD_NUMBER}

                        echo ">>> Run JMeter load test"
                        ~/jmeter/bin/jmeter -n -t ~/plans/loadtest.jmx -l ~/plans/result.jtl
                    '
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished (BUILD #${env.BUILD_NUMBER})"
        }
    }
}
