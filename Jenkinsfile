pipeline {
  agent any

  parameters {
    string(name: 'TEACHER_CODE', defaultValue: 'TEST SUCCESS', description: 'Expected /getcode & container ENV')
    string(name: 'ROBOT_BASE_VM2', defaultValue: 'http://vm2.local:8081', description: 'Robot BASE for VM2 sanity')
    string(name: 'ROBOT_BASE_VM3', defaultValue: 'http://vm3.local',     description: 'Robot BASE for VM3 pre-prod')
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

    
    stage('Build & Unit/Robot on VM2') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId:'ssh-vm2',keyFileVariable:'K2',usernameVariable:'U2')]) {
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "set -e
            rm -rf ~/ci && mkdir -p ~/ci && cd ~/ci
            git clone ${REPO_API} simple-api
            cd simple-api
            if [ -x ./run_unit_test.sh ]; then ./run_unit_test.sh; else echo 'skip unit test'; fi

            docker build -f app/Dockerfile -t ${REGISTRY}:${env.BUILD_NUMBER} .
            (docker ps -aq --filter name=simple-api && docker rm -f simple-api) || true
            docker run -d --name simple-api -e TEACHER_CODE='${params.TEACHER_CODE}' -p 8081:5000 ${REGISTRY}:${env.BUILD_NUMBER} || true

            // cd .. && git clone ${REPO_ROBOT} simple-api-robot
            // cd simple-api-robot
            // python3 -m pip install --user --upgrade pip
            // if [ -f requirements.txt ]; then
            //   python3 -m pip install --user -r requirements.txt
            // else
            //   python3 -m pip install --user robotframework robotframework-requests requests
            // fi
            // export PATH=\\"\\$HOME/.local/bin:\\$PATH\\"
            // mkdir -p results
            // robot -d results -v BASE:'${params.ROBOT_BASE_VM2}' -v EXPECT_CODE:'${params.TEACHER_CODE}' tests/ || (echo 'Robot test failed (VM2)' && exit 1)

            docker push ${REGISTRY}:${env.BUILD_NUMBER}
          "
          """

          // ดึงรายงานกลับ Jenkins
          sh """
            rm -rf robot_results_vm2 && mkdir -p robot_results_vm2
            scp -i "$K2" -o StrictHostKeyChecking=no -r "$U2@${VM2_HOST}:~/ci/simple-api-robot/results/" robot_results_vm2/
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
          // ดึงรายงานกลับ Jenkins
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
      // ถ้ามีปลั๊กอิน Robot → เปิดคอมเมนต์บรรทัดล่าง
      // robot outputPath: 'robot_results_vm2', passThreshold: 100.0, unstableThreshold: 0.0
      // robot outputPath: 'robot_results_vm3', passThreshold: 100.0, unstableThreshold: 0.0

      archiveArtifacts artifacts: 'robot_results_vm2/**/*', fingerprint: true, onlyIfSuccessful: false
      archiveArtifacts artifacts: 'robot_results_vm3/**/*', fingerprint: true, onlyIfSuccessful: false
    }
  }
}