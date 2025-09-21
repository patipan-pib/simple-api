pipeline {
  agent any

  environment {
    // Hosts
    VM2_HOST = "10.162.209.192"   // Test/Build
    VM3_HOST = "10.162.209.18"    // Pre-Prod/Deploy

    // Git repos
    REPO_API   = "git@github.com:patipan-pib/simple-api.git"
    REPO_ROBOT = "git@github.com:patipan-pib/simple-api-robot.git"

    // Private registry (running on VM2:5000)
    REGISTRY   = "10.162.209.192:5000/simple-api"
  }

  stages {
    stage('Checkout SCM') {
      steps {
        echo "Cloning repo with 'github_ssh' (configured in job SCM)"
        // Jenkins will checkout using the job's SCM config & github_ssh credential
      }
    }

    stage('Check bound keys (VM2 & VM3)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2',
                                           keyFileVariable: 'K2',
                                           usernameVariable: 'U2')]) {
          sh 'ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "echo CONNECTED_VM2 && hostname && whoami"'
        }
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3',
                                           keyFileVariable: 'K3',
                                           usernameVariable: 'U3')]) {
          sh 'ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" "echo CONNECTED_VM3 && hostname && whoami"'
        }
      }
    }

    stage('Build & Test on VM2') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2',
                                           keyFileVariable: 'K2',
                                           usernameVariable: 'U2')]) {
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" '
            set -e
            rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci

            echo ">>> Clone API repo"
            git clone ${REPO_API} simple-api
            cd simple-api

            echo ">>> Unit test (skip if script not found)"
            if [ -x ./run_unit_test.sh ]; then ./run_unit_test.sh; else echo "skip unit test"; fi

            echo ">>> Build Docker image"
            docker build -t ${REGISTRY}:\${BUILD_NUMBER} .

            echo ">>> (Optional) Run temp container for sanity"
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -p 8081:8080 ${REGISTRY}:\${BUILD_NUMBER} || true

            echo ">>> Robot test (skip if repo/tests not found)"
            cd .. && git clone ${REPO_ROBOT} simple-api-robot || true
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
            docker push ${REGISTRY}:\${BUILD_NUMBER}

            echo ">>> Cleanup temp container"
            docker rm -f simple-api || true
          '
          """
        }
      }
    }

    stage('Deploy & Load Test on VM3') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3',
                                           keyFileVariable: 'K3',
                                           usernameVariable: 'U3')]) {
          sh """
          ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" '
            set -e

            echo ">>> Pull image from registry"
            docker pull ${REGISTRY}:\${BUILD_NUMBER}

            echo ">>> Restart container"
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -p 80:8080 ${REGISTRY}:\${BUILD_NUMBER}

            echo ">>> JMeter load test (skip if jmeter/plan not present)"
            if [ -x ~/jmeter/bin/jmeter ] && [ -f ~/plans/loadtest.jmx ]; then
              ~/jmeter/bin/jmeter -n -t ~/plans/loadtest.jmx -l ~/plans/result.jtl
            else
              echo "skip jmeter (binary/plan not found)"
            fi
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
