pipeline {
  agent any

  parameters {
  string(name: 'ROBOT_BASE', defaultValue: 'http://vm2.local:8081', description: 'Robot test BASE URL')
  string(name: 'ROBOT_EXPECT', defaultValue: 'ABC123', description: 'Expected teacher code for /getcode')
  }


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

    
    stage('Build & Test on VM2 (Robot)') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ssh-vm2', keyFileVariable: 'K2', usernameVariable: 'U2')]) {
          // ใช้ """ (double-quoted GString) ได้ แต่อ้างอิงตัวแปร Jenkins ให้ใช้ ${params.X}
          // และเวลาอยากส่ง $ ให้ฝั่ง shell ให้ escape เป็น \$ เสมอ
          sh """
          ssh -i "$K2" -o StrictHostKeyChecking=no "$U2@${VM2_HOST}" "set -e
            mkdir -p ~/ci && cd ~/ci
            rm -rf simple-api-robot
            git clone ${REPO_ROBOT} simple-api-robot
            cd simple-api-robot

            python3 -m pip install --user --upgrade pip
            if [ -f requirements.txt ]; then
              python3 -m pip install --user -r requirements.txt
            else
              python3 -m pip install --user robotframework robotframework-requests requests
            fi
            export PATH=\\\"\\$HOME/.local/bin:\\$PATH\\\"

            # 2) ส่งค่าจาก Jenkins parameters ไปเป็น ENV ใน shell ฝั่ง VM2
            export ROBOT_BASE='${params.ROBOT_BASE}'
            export ROBOT_EXPECT='${params.ROBOT_EXPECT}'

            mkdir -p results
            robot -d results -v BASE:\\$ROBOT_BASE -v EXPECT_CODE:\\$ROBOT_EXPECT tests/ || (echo 'Robot test failed' && exit 1)
          "

          # ดึงผลกลับ Jenkins (optional แต่แนะนำ)
          rm -rf robot_results && mkdir -p robot_results
          scp -i "$K2" -o StrictHostKeyChecking=no -r "$U2@${VM2_HOST}:~/ci/simple-api-robot/results/" robot_results/
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