pipeline {
  agent any

  parameters {
    string(name: 'TEACHER_CODE', defaultValue: 'success', description: 'Expected /getcode & container ENV')
    string(name: 'ROBOT_BASE_VM2', defaultValue: 'http://vm2.local:8081', description: 'Robot BASE for VM2 sanity')
    string(name: 'ROBOT_BASE_VM3', defaultValue: 'http://vm3.local', description: 'Robot BASE for VM3 pre-prod')
  }
  environment {
    VM1_HOST   = "vm1.local"  // Jenkins
    VM2_HOST   = "vm2.local"  // Test/Build
    VM3_HOST   = "vm3.local"  // Pre-Prod
    REPO_API   = "https://github.com/patipan-pib/simple-api.git"
    REPO_ROBOT = "https://github.com/patipan-pib/simple-api-robot.git"
    REGISTRY   = "vm2.local:5000/simple-api"

    GHCR_REGISTRY  = "ghcr.io"
    GHCR_IMAGE     = "ghcr.io/patipan-pib/simple-api"   // ชื่อ container บน GHCR
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
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2'),
          string(credentialsId: 'ghcr_pat', variable: 'GHCR_PAT')
        ]) {
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "set -e
            rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci

            echo '>>> Clone API repo'
            git clone ${REPO_API} simple-api
            cd simple-api

            echo '>>> Unit test (skip if script not found)'
            python3 -m pip install --user -U pip
            python3 -m pip install --user -r app/requirements.txt
            export PATH="$HOME/.local/bin:$PATH"
            python3 -m unittest -v unit_test.py

            echo '>>> Build Docker image'
            GIT_SHA=\$(git rev-parse --short HEAD)
            docker build -f app/Dockerfile -t ${REGISTRY}:${env.BUILD_NUMBER} .

            echo '>>> (Optional) Sanity run'
            # (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            # docker run -d --name simple-api -p 8081:5000 ${REGISTRY}:${env.BUILD_NUMBER} || true
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -e TEACHER_CODE="${TEACHER_CODE}" -p 8081:5000 "${REGISTRY}:${env.BUILD_NUMBER}" || true

            echo '>>> Robot test'
            cd .. && git clone --depth 1 "$REPO_ROBOT" simple-api-robot || true
            if [ -d simple-api-robot ]; then
              cd simple-api-robot
              # ติดตั้งให้ชัวร์ แล้วเรียกผ่านโมดูล
              python3 -m pip install --user -U pip robotframework robotframework-requests requests
              mkdir -p results

              # เลือกตำแหน่งเทสอัตโนมัติ
              if [ -d tests ] && ls -1 tests/*.robot >/dev/null 2>&1; then
                python3 -m robot -d results -v BASE:"${ROBOT_BASE_VM2}" -v EXPECT_CODE:"${TEACHER_CODE}" tests/ \
                  || (echo 'Robot test failed' && exit 1)
              elif ls -1 ./*.robot >/dev/null 2>&1; then
                python3 -m robot -d results -v BASE:"${ROBOT_BASE_VM2}" -v EXPECT_CODE:"${TEACHER_CODE}" ./*.robot \
                  || (echo 'Robot test failed' && exit 1)
              else
                echo 'ERROR: No .robot files found' && exit 250
              fi
            else
              echo 'skip robot (repo not found)'
            fi
          
            echo '>>> Push image to registry'
            docker push ${REGISTRY}:${env.BUILD_NUMBER}

            echo '>>> Login to GitHub Container Registry (GHCR)'
            echo '$GHCR_PAT' | docker login ghcr.io -u patipan-pib --password-stdin

            echo '>>> Tag & Push image to GHCR'
            docker tag ${REGISTRY_LOCAL}:${env.BUILD_NUMBER} ghcr.io/patipan-pib/simple-api:latest
            docker tag ${REGISTRY_LOCAL}:${env.BUILD_NUMBER} ghcr.io/patipan-pib/simple-api:${env.BUILD_NUMBER}
            docker tag ${REGISTRY_LOCAL}:${env.BUILD_NUMBER} ghcr.io/patipan-pib/simple-api:\\$GIT_SHA

            docker push ghcr.io/patipan-pib/simple-api:latest
            docker push ghcr.io/patipan-pib/simple-api:${env.BUILD_NUMBER}
            docker push ghcr.io/patipan-pib/simple-api:\\$GIT_SHA

            echo '>>> Cleanup temp container'
            docker rm -f simple-api || true
          "
          """
        }
      }
    }

    stage('Deploy & Sanity/Load on VM3') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId:'ssh-vm3',keyFileVariable:'K3',usernameVariable:'U3')]) {
          sh """
          ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" "set -e
            docker pull ${REGISTRY}:${env.BUILD_NUMBER}
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -e TEACHER_CODE='${params.TEACHER_CODE}' -p 80:5000 ${REGISTRY}:${env.BUILD_NUMBER}

            # optional jmeter
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
    }
  }
}