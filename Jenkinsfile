pipeline {
  agent any

  environment {
    SONARQUBE_SERVER_NAME = 'SonarQube'         // Jenkins > Configure System > SonarQube servers (Name)
    SONAR_SCANNER_TOOL    = 'SonarQube-Scanner' // Jenkins > Global Tool Config (Name)
    SONAR_PROJECT_KEY     = 'my-14848.linecount'// Any unique string
    HADOOP_USER           = 'ananya'            // Linux user on Hadoop master
    HADOOP_HOST           = '136.112.107.232'   // External IP of hadoop-cluster-m
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  triggers {
    // Requires GitHub webhook to Jenkins: http://<jenkins>/github-webhook/
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'echo "Workspace: $PWD"; ls -la'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE_SERVER_NAME}") {
          script {
            def scannerHome = tool "${SONAR_SCANNER_TOOL}"
            sh """
              ${scannerHome}/bin/sonar-scanner \
                -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                -Dsonar.projectName=${SONAR_PROJECT_KEY} \
                -Dsonar.sources=. \
                -Dsonar.host.url=${SONAR_HOST_URL} \
                -Dsonar.login=${SONAR_AUTH_TOKEN}
            """
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 10, unit: 'MINUTES') {
          script {
            def qg = waitForQualityGate()   // SonarQube -> Jenkins webhook recommended
            echo "Quality Gate: ${qg.status}"
            if (qg.status != 'OK') {
              error "Quality Gate failed: ${qg.status}"
            }
          }
        }
      }
    }

    stage('Run Hadoop MapReduce (per-file line counts)') {
      steps {
        sshagent(credentials: ['hadoop-ssh-key']) {
          sh """
            # 1) Copy repo + scripts to Hadoop master
            rsync -avz -e "ssh -o StrictHostKeyChecking=no" ./ ${HADOOP_USER}@${HADOOP_HOST}:/tmp/workspace-${env.BUILD_TAG}/

            # 2) Run the job on the master
            ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} \\
              'cd /tmp/workspace-${env.BUILD_TAG} && \\
               chmod +x mapper.py reducer.py run_hadoop_linecount.sh && \\
               WORKDIR=/tmp/workspace-${env.BUILD_TAG} bash ./run_hadoop_linecount.sh'
          """
        }
      }
    }

    stage('Fetch & Display Results') {
      steps {
        sshagent(credentials: ['hadoop-ssh-key']) {
          sh """
            scp -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST}:/tmp/workspace-${env.BUILD_TAG}/linecount.txt .
          """
        }
        echo "===== Hadoop Line Counts ====="
        sh 'cat linecount.txt || true'
        archiveArtifacts artifacts: 'linecount.txt', onlyIfSuccessful: true, allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      echo 'Done.'
    }
    cleanup {
      // optional: purge remote temp workspace
      sshagent(credentials: ['hadoop-ssh-key']) {
        sh 'ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "rm -rf /tmp/workspace-${BUILD_TAG}" || true'
      }
    }
  }
}
