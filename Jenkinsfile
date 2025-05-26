def EC2_IP = ''
def IMAGE_REPO = ''

pipeline {
  agent any

  stages {
    stage('Define AWS Variable'){
      steps {
        script {
          withAWS(credentials: 'aws-credentials', region: 'us-east-1') {
            EC2_IP = sh (
              script: 'aws ec2 describe-instances --filters "Name=tag:Name,Values=public_instance" --query "Reservations[*].Instances[*].PublicIpAddress" --output text',
              returnStdout: true
            ).trim()
            IMAGE_REPO = sh (
              script: 'aws ecr describe-repositories --repository-names flask --query "repositories[*].repositoryUri" --output text',
              returnStdout: true
            ).trim()
          }
          echo "${EC2_IP}"
          echo "${IMAGE_REPO}"
        }
      }
    }
    stage('Copy Python Application Source Code to EC2 instance'){
      steps {
        script {
          sshagent(['devops-linux-private-key']) {
            sh """
              scp -r -o StrictHostKeyChecking=no ./src ec2-user@${EC2_IP}:src/
              scp -o StrictHostKeyChecking=no ./Dockerfile ec2-user@${EC2_IP}:Dockerfile
            """
          }
        }
      }
    }
    stage('Build Docker Image'){
      steps {
        script {
          sshagent(['devops-linux-private-key']) {
            sh """
              ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '
                docker build -t flask .
                docker tag flask ${IMAGE_REPO}:${BUILD_NUMBER}
              '
            """
          }
        }
      }
    }
    stage('Push Image To ECR Repository'){
      steps {
        script {
          sshagent(['devops-linux-private-key']) {
            sh """
              ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '
                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${IMAGE_REPO}
                docker push ${IMAGE_REPO}:${BUILD_NUMBER}
              '
            """
          }
        }
      }
    }
    stage('Deploy Flask Application'){
      steps {
        script {
          sshagent(['devops-linux-private-key']) {
            sh """
              ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '
                if docker ps | grep -iq flask; then
                  docker stop flask
                  docker rm flask
                fi
                docker run -d -p 80:5000 --name flask ${IMAGE_REPO}:${BUILD_NUMBER}
              '
            """
          }
        }
      }
    }
  }
}
