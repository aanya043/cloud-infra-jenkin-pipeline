pipeline {
  agent any

  environment {
    SONARQUBE_SERVER_NAME = 'SonarQube'
    SONAR_SCANNER_TOOL    = 'SonarQube-Scanner'
    SONAR_PROJECT_KEY     = 'my-14848.linecount'
    HADOOP_USER           = 'ananya'
    HADOOP_HOST           = '136.112.107.232'
  }

  triggers { githubPush() }

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
            def qg = waitForQualityGate()
            echo "Quality Gate: ${qg.status}"
            if (qg.status != 'OK') { error "Quality Gate failed: ${qg.status}" }
          }
        }
      }
    }

    stage('Run Hadoop MapReduce (per-file line counts)') {
      steps {
        sshagent(credentials: ['ananya-ssh']) {
          sh '''
            set -euxo pipefail
            REMOTE_DIR="/tmp/workspace-${BUILD_TAG}"

            # Create remote dir
            ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "mkdir -p ${REMOTE_DIR}"

            # Copy repo (no rsync needed)
            tar -cf - . | ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "tar -xf - -C ${REMOTE_DIR}"

            # Show what arrived
            ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "set -eux; ls -la ${REMOTE_DIR}"

            # Ensure script exists (use the actual filename in your repo)
            ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "test -f ${REMOTE_DIR}/run_hadoop_linecount.sh || (echo 'run_hadoop_linecount.sh not found!' >&2; exit 2)"

            # Run the job (login shell to get PATH for hadoop/python)
            ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "bash -lc 'cd ${REMOTE_DIR} && chmod +x mapper.py reducer.py run_hadoop_job.sh && WORKDIR=${REMOTE_DIR} ./run_hadoop_job.sh'"
          '''
        }
      }
    }



    stage('Fetch & Display Results') {
      steps {
        sshagent(credentials: ['ananya-ssh']) {
          sh 'scp -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST}:/tmp/workspace-${env.BUILD_TAG}/linecount.txt . || true'
        }
        echo "===== Hadoop Line Counts ====="
        sh 'cat linecount.txt || true'
        archiveArtifacts artifacts: 'linecount.txt', onlyIfSuccessful: true, allowEmptyArchive: true
      }
    }
  }

  post {
    always { echo 'Done.' }
    cleanup {
      sshagent(credentials: ['ananya-ssh']) {
        sh 'ssh -o StrictHostKeyChecking=no ${HADOOP_USER}@${HADOOP_HOST} "rm -rf /tmp/workspace-${BUILD_TAG}" || true'
      }
    }
  }
}
