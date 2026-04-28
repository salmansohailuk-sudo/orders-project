pipeline {
  agent any

  /**************************************
   * GLOBAL ENV VARIABLES
   **************************************/
  environment {
    REGION = "us-east-1"
  }

  /**************************************
   * OPTIONAL PARAMETER (IMPORTANT)
   * Allows you to control Terraform run
   **************************************/
  parameters {
    booleanParam(
      name: 'RUN_TERRAFORM',
      defaultValue: false,
      description: 'Run Terraform Apply (ONLY when infra changes)'
    )
  }

  stages {

    /**************************************
     * STAGE 1: CHECKOUT CODE FROM GITHUB
     **************************************/
    stage('Checkout Code') {
      steps {
        // Pull latest code from GitHub repo
        git branch: 'main', url: 'https://github.com/salmansohailuk-sudo/orders-project.git'
        
      }
    }

    /**************************************
     * STAGE 2: GENERATE VERSION TAG
     **************************************/
    stage('Set Version') {
      steps {
        script {
          /*
          This script generates a version like:
          build-1, build-2, etc.
          Used for tagging Docker images
          */
          env.VERSION = sh(
            script: "bash scripts/version.sh",
            returnStdout: true
          ).trim()
        }
      }
    }

    /**************************************
     * STAGE 3: ZIP LAMBDA FUNCTIONS
     **************************************/
    stage('Zip Lambdas') {
      steps {
        sh '''
        echo "Creating Lambda ZIP files..."

        chmod +x scripts/zip.sh
        ./scripts/zip.sh

        echo "ZIP files ready:"
        ls -lh *.zip
        '''
      }
    }

    /**************************************
     * STAGE 4: TERRAFORM (OPTIONAL)
     **************************************/
    stage('Terraform Apply') {
      when {
        expression { return params.RUN_TERRAFORM == true }
      }
      steps {
        sh '''
        echo "Running Terraform..."

        cd terraform

        terraform init
        terraform apply -auto-approve

        echo "Terraform complete"
        '''
      }
    }

    /**************************************
     * STAGE 5: UPDATE LAMBDA CODE
     **************************************/
    stage('Deploy Lambdas') {
      steps {
        sh '''
        echo "Updating Lambda functions..."

        aws lambda update-function-code \
          --function-name orders-producer \
          --zip-file fileb://producer.zip

        aws lambda update-function-code \
          --function-name orders-consumer \
          --zip-file fileb://consumer.zip

        aws lambda update-function-code \
          --function-name orders-status \
          --zip-file fileb://status.zip

        echo "Lambda deployment complete"
        '''
      }
    }

    /**************************************
     * STAGE 6: BUILD & PUSH FRONTEND TO ECR
     **************************************/
    stage('Build & Push Frontend') {
      steps {
        sh '''
        echo "Building and pushing frontend..."

        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        ECR="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/orders-frontend"

        echo "Logging into ECR..."
        aws ecr get-login-password --region $REGION \
        | docker login --username AWS --password-stdin $ECR

        echo "Building Docker image..."
        docker build -t orders-frontend ./frontend

        echo "Tagging images..."
        docker tag orders-frontend:latest $ECR:latest
        docker tag orders-frontend:latest $ECR:$VERSION

        echo "Pushing images..."
        docker push $ECR:latest
        docker push $ECR:$VERSION

        echo "Frontend pushed to ECR"
        '''
      }
    }

    /**************************************
     * STAGE 7: RUN FRONTEND CONTAINER
     **************************************/
    stage('Deploy Frontend (EC2)') {
      steps {
        sh '''
        echo "Deploying frontend container..."

        # Stop old container if exists
        docker stop frontend || true

        # Remove old container
        docker rm frontend || true

        # Run new container
        docker run -d -p 80:80 --name frontend orders-frontend

        echo "Frontend running on port 80"
        '''
      }
    }

  }

  /**************************************
   * POST BUILD ACTIONS
   **************************************/
  post {
    success {
      echo "✅ Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed! Check logs."
    }
  }
}