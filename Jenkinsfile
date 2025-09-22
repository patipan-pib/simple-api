pipeline {
  agent any

  environment {
    // Hosts
    VM2_HOST = "vm2.local"   // Test/Build
    VM3_HOST = "vm3.local"    // Pre-Prod/Deploy

    // Repos (HTTPS เพื่อไม่ต้องมี SSH key บน VM2)
    REPO_API   = "https://github.com/patipan-pib/simple-api.git"
    REPO_ROBOT = "https://github.com/patipan-pib/simple-api-robot.git"

    // Private Registry (running on VM2:5000; ensure VM3 allows insecure registry)
    REGISTRY   = "vm2.local:5000/simple-api"
    TEACHER_CODE = "ABC123"
  }

  stages {
    stage('Checkout SCM') {
      steps {
        echo "SCM uses credential 'github_ssh' from job config"
      }
    }

    stage('Check bound keys (VM2 & VM3)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2')]) {
          sh 'ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "echo CONNECTED_VM2 && hostname && whoami"'
        }
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3', keyFileVariable: 'K3', usernameVariable: 'U3')]) {
          sh 'ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" "echo CONNECTED_VM3 && hostname && whoami"'
        }
      }
    }

    stage('Build & Test on VM2') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2')]) {
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "set -e
            rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci

            git clone ${REPO_API} simple-api
            cd simple-api

            if [ -x ./run_unit_test.sh ]; then ./run_unit_test.sh || exit 1; else echo 'skip unit test'; fi

            docker build -f app/Dockerfile -t ${REGISTRY}:${env.BUILD_NUMBER} .

            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            # sanity run พร้อม ENV
            docker run -d --name simple-api -e TEACHER_CODE='${TEACHER_CODE}' -p 8081:5000 ${REGISTRY}:${env.BUILD_NUMBER} || true

            cd .. && git clone ${REPO_ROBOT} simple-api-robot || true
            if [ -d simple-api-robot ]; then
              cd simple-api-robot
              if command -v robot >/dev/null 2>&1; then
                mkdir -p results
                robot -d results tests/ || (echo 'Robot test failed' && exit 1)
              else
                echo 'skip robot (robot not installed)'
              fi
            else
              echo 'skip robot (repo not found)'
            fi

            docker push ${REGISTRY}:${env.BUILD_NUMBER}
            docker rm -f simple-api || true
          "
          """
        }
      }
    }

    stage('Deploy & Load Test on VM3') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm3', keyFileVariable: 'K3', usernameVariable: 'U3')]) {
          sh """
          ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" "set -e
            docker pull ${REGISTRY}:${env.BUILD_NUMBER}
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -e TEACHER_CODE='${TEACHER_CODE}' -p 80:5000 ${REGISTRY}:${env.BUILD_NUMBER}

            if [ -x ~/jmeter/bin/jmeter ] && [ -f ~/plans/loadtest.jmx ]; then
              ~/jmeter/bin/jmeter -n -t ~/plans/loadtest.jmx -Jthreads=10 -Jrampup=10 -l ~/plans/result.jtl -e -o ~/plans/html
            else
              echo 'skip jmeter (binary/plan not found)'
            fi
          "
          """
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished (BUILD #${env.BUILD_NUMBER})"

      // ถ้าเราดึงผลกลับ Jenkins master ได้ ให้เก็บไว้ (ตัวอย่างสมมติ path/workspace)
      // junit 'reports/*.xml'
      // robot outputPath: 'simple-api-robot/results', passThreshold: 100.0, unstableThreshold: 0.0
      // archiveArtifacts artifacts: 'simple-api-robot/results/**/*, plans/result.jtl', fingerprint: true, onlyIfSuccessful: false
    }
  }
}