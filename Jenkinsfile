pipeline {
    
    agent any

    environment {
        SONAR_HOME = tool "Sonar"
        IMAGE_NAME = "todo-node-app"
    }

    stages {
        
        stage("Code") {
            steps {
                git url: "https://github.com/roohmeiy/todo-node-app.git", branch: "main"
                echo "Code Cloned Successfully"
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv("Sonar") {
                    sh "$SONAR_HOME/bin/sonar-scanner -Dsonar.projectName=nodetodo -Dsonar.projectKey=nodetodo -X"
                }
            }
        }

        stage("SonarQube Quality Gates") {
            steps {
                timeout(time: 1, unit: "MINUTES") {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage("OWASP") {
            steps {
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'OWASP'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage("Build & Test") {
            steps {
                sh "docker build -t ${IMAGE_NAME}:latest ."
                echo "Code Build Successful"
            }
        }

        stage("Trivy") {
            steps {
                sh "trivy image ${IMAGE_NAME}:latest"
            }
        }

        stage("Push to Docker Hub Repo") {
            steps {
                withCredentials([usernamePassword(credentialsId: "DockerHubCreds", passwordVariable: "dockerPass", usernameVariable: "dockerUser")]) {
                    sh "docker login -u ${env.dockerUser} -p ${env.dockerPass}"
                    sh "docker tag ${IMAGE_NAME}:latest ${env.dockerUser}/${IMAGE_NAME}:latest"
                    sh "docker push ${env.dockerUser}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage("Deploy") {
            steps {
                sh "docker-compose down && docker-compose up -d"
                echo "App Deployed Successfully"
            }
        }
    }
}
