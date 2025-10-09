pipeline {
    agent any
    tools {
        jdk 'JDK 11'
    }
    environment {
        HADOOP_IP = '34.133.31.146' 
        GCS_BUCKET = 'hadoop-jobs-bucket-165fb971'  // Replace with bucket name from Step 1
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/aanya043/python-code-disasters.git', branch: 'main'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarQube Scanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=python-code-disasters -Dsonar.sources=."
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Run Hadoop Job') {
            when { expression { env.QUALITY_GATE == 'PASSED' } }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'hadoop-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                    ssh -i $SSH_KEY -o StrictHostKeyChecking=no YOUR_USERNAME@$HADOOP_IP 'bash -s' < run_hadoop_job.sh
                    '''
                }
            }
        }
    }
    post {
        success {
            sh '''
            gsutil cp gs://$GCS_BUCKET/results.txt .
            echo "<html><body><h2>Hadoop Job Results</h2><pre>$(cat results.txt)</pre></body></html>" > results.html
            '''
            archiveArtifacts artifacts: 'results.html', allowEmptyArchive: true
        }
    }
}