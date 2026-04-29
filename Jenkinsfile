pipeline {
  agent any

  environment {
    REGION = "us-east-1"
  }

  stages {

    stage('Checkout Code') {
      steps {
        // Pull latest code from GitHub repo
        git branch: 'main', url: 'https://github.com/UmmeHani-git/orders-project.git'
        
      }
    }

    stage('Version') {
      steps {
        script {
          env.VERSION = sh(
            script: "bash scripts/version.sh",
            returnStdout: true
          ).trim()
        }
      }
    }

    // ✅ STEP 1: ZIP LAMBDAS
    stage('Zip Lambdas') {
      steps {
        sh '''
        chmod +x scripts/zip.sh
        ./scripts/zip.sh
        '''
      }
    }

    // ✅ STEP 2: Terraform (SAFE MODE)
    stage('Terraform Plan Only') {
      steps {
        sh '''
        cd terraform
        terraform init
        terraform plan
        '''
      }
    }

    // ✅ STEP 3: UPDATE LAMBDAS (AUTO)
    stage('Update Lambdas') {
      steps {
        sh '''
        aws lambda update-function-code --function-name orders-producer --zip-file fileb://producer.zip
        aws lambda update-function-code --function-name orders-consumer --zip-file fileb://consumer.zip
        aws lambda update-function-code --function-name orders-status --zip-file fileb://status.zip
        '''
      }
    }

    // ✅ STEP 4: BUILD + PUSH DOCKER
    stage('Build & Push Frontend') {
      steps {
        sh '''
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

        ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/orders-frontend"

        aws ecr get-login-password --region $REGION \
        | docker login --username AWS --password-stdin $ECR

        docker build -t orders-frontend ./frontend

        docker tag orders-frontend:latest $ECR:latest
        docker tag orders-frontend:latest $ECR:$VERSION

        docker push $ECR:latest
        docker push $ECR:$VERSION
        '''
      }
    }

    // ✅ STEP 5: AUTO STOP OLD + RUN NEW (FIXED)
    stage('Run Frontend') {
      steps {
        sh '''
        echo "Stopping old container if exists..."

        docker ps -q --filter "name=frontend" | grep -q . && docker stop frontend || true
        docker ps -aq --filter "name=frontend" | grep -q . && docker rm frontend || true

        echo "Starting new container..."

        docker run -d -p 80:80 --name frontend orders-frontend
        '''
      }
    }

  }
} 
