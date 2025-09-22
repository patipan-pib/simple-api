pipeline {
  agent any

  parameters {
    string(name: 'TEACHER_CODE', defaultValue: 'TEST SUCCESS', description: 'Expected /getcode & container ENV')
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

    // stage('Build & Unit/Robot on VM2') {
    //   steps {
    //     withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2')]) {
    //       // Step 1: Setup workspace
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci
    //         echo "Workspace setup completed"
    //         REMOTE
    //       """

    //       // Step 2: Clone API repository
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci
    //         git clone "${REPO_API}" simple-api || { echo "Failed to clone API repo"; exit 1; }
    //         echo "API repository cloned"
    //         REMOTE
    //       """

    //       // Step 3: Run unit tests (optional)
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci/simple-api
    //         if [ -x ./run_unit_test.sh ]; then 
    //           ./run_unit_test.sh || { echo "Unit test failed"; exit 1; }
    //         else 
    //           echo "Skipping unit test (run_unit_test.sh not found or not executable)"
    //         fi
    //         REMOTE
    //       """

    //       // Step 4: Build Docker image
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci/simple-api
    //         docker build -f app/Dockerfile -t "${REGISTRY}:${BUILD_NUMBER}" . || { echo "Docker build failed"; exit 1; }
    //         echo "Docker image built: ${REGISTRY}:${BUILD_NUMBER}"
    //         REMOTE
    //       """

    //       // Step 5: Run Docker container
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         docker ps -aq --filter name=simple-api | xargs -r docker rm -f || true
    //         docker run -d --name simple-api \
    //           -e TEACHER_CODE="${TEACHER_CODE}" \
    //           -p 8081:5000 "${REGISTRY}:${BUILD_NUMBER}" || { echo "Docker run failed"; exit 1; }
    //         echo "Docker container started"
    //         REMOTE
    //       """

    //       // Step 6: Clone Robot repository
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci
    //         git clone --depth 1 "${REPO_ROBOT}" simple-api-robot || { echo "Failed to clone Robot repo"; exit 1; }
    //         echo "Robot repository cloned"
    //         REMOTE
    //       """

    //       // Step 7: Install Robot Framework dependencies
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci/simple-api-robot
    //         python3 -m pip install --user -U pip robotframework robotframework-requests requests || { echo "Pip install failed"; exit 1; }
    //         export PATH="$HOME/.local/bin:$PATH"
    //         python3 -m robot --version
    //         echo "Robot Framework dependencies installed"
    //         REMOTE
    //       """

    //       // Step 8: Run Robot Framework tests
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         cd ~/ci/simple-api-robot
    //         mkdir -p results
    //         python3 -m robot -d results \
    //           -v BASE:"${ROBOT_BASE_VM2}" \
    //           -v EXPECT_CODE:"${TEACHER_CODE}" \
    //           tests/ || { echo "Robot test failed (VM2)"; exit 1; }
    //         echo "Robot tests completed"
    //         REMOTE
    //       """

    //       // Step 9: Push Docker image
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@$VM2_HOST" bash -s <<'REMOTE'
    //         set -euo pipefail
    //         docker push "${REGISTRY}:${BUILD_NUMBER}" || { echo "Docker push failed"; exit 1; }
    //         echo "Docker image pushed"
    //         REMOTE
    //       """

    //       // Step 10: Copy Robot results back to Jenkins
    //       sh """#!/usr/bin/env bash
    //         set -euo pipefail
    //         rm -rf robot_results_vm2 && mkdir -p robot_results_vm2
    //         scp -o StrictHostKeyChecking=no -r "$U2@$VM2_HOST:~/ci/simple-api-robot/results/" robot_results_vm2/
    //         echo "Robot results copied to Jenkins"
    //       """
    //     }
    //   }
    // }

    stage('Build & Test on VM2') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2')]) {
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "set -e
            rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci

            echo '>>> Clone API repo'
            git clone ${REPO_API} simple-api
            cd simple-api

            echo '>>> Unit test (skip if script not found)'
            if [ -x ./run_unit_test.sh ]; then ./run_unit_test.sh; else echo 'skip unit test'; fi
            
            echo '>>> Build Docker image'
            docker build -f app/Dockerfile -t ${REGISTRY}:${env.BUILD_NUMBER} .

            echo '>>> (Optional) Sanity run'
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -p 8081:5000 ${REGISTRY}:${env.BUILD_NUMBER} || true

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

    stage('Robot on VM3 (Pre-Prod)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId:'ssh-vm3',keyFileVariable:'K3',usernameVariable:'U3')]) {
          sh """
          ssh -i "$K3" -o StrictHostKeyChecking=no "$U3@${VM3_HOST}" "set -e
            rm -rf ~/ci-robot && mkdir -p ~/ci-robot && cd ~/ci-robot
            git clone ${REPO_ROBOT} simple-api-robot
            cd simple-api-robot
            python3 -m pip install --user --upgrade pip robotframework robotframework-requests requests
            export PATH=\\"\\$HOME/.local/bin:\\$PATH\\"
            mkdir -p results
            robot -d results -v BASE:'${params.ROBOT_BASE_VM3}' -v EXPECT_CODE:'${params.TEACHER_CODE}' tests/ || (echo 'Robot test failed (VM3)' && exit 1)
          "
          """
          sh """
            rm -rf robot_results_vm3 && mkdir -p robot_results_vm3
            scp -i "$K3" -o StrictHostKeyChecking=no -r "$U3@${VM3_HOST}:~/ci-robot/simple-api-robot/results/" robot_results_vm3/
          """
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'robot_results_vm2/**/*', fingerprint: true, onlyIfSuccessful: false
      archiveArtifacts artifacts: 'robot_results_vm3/**/*', fingerprint: true, onlyIfSuccessful: false
    }
  }
}