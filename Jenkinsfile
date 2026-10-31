pipeline {
    agent any
	options {
	    skipDefaultCheckout(true)
	}    

    tools {
        maven 'Maven'
    }

    stages {
	stage('Checkout') {
	    steps {
		checkout scm
	    }
	}

        stage('Build JAR') {
            steps {
                sh 'mvn -version'
                sh 'mvn -B clean package'
                sh 'ls -lh target/*.jar'
            }
        }
        stage('Build Image') {
            steps {
                sh 'docker build -t ellouz/hello-api:jenkins-test .'
                sh 'docker image ls ellouz/hello-api:jenkins-test'
            }
        }
        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh '''
                        set +x
                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT
        
                        printf '%s' "$DOCKER_TOKEN" |
                            docker login --username "$DOCKER_USER" --password-stdin
        
                        docker push ellouz/hello-api:jenkins-test
                    '''
                }
            }
        }
        stage('Deploy EC2') {
            steps {
                sshagent(credentials: ['ec2-server-key']) {
                    sh '''
                        ssh -o BatchMode=yes \
                            -o StrictHostKeyChecking=yes \
                            -o ConnectTimeout=10 \
                            ec2-user@13.60.209.116 'bash -se' <<'REMOTE'
        set -e
        
        sudo docker pull ellouz/hello-api:jenkins-test
        
        if sudo docker container inspect hello-api >/dev/null 2>&1; then
            sudo docker stop hello-api
            sudo docker rm hello-api
        fi
        
        sudo docker run -d \
            --name hello-api \
            --restart unless-stopped \
            -p 8080:8080 \
            ellouz/hello-api:jenkins-test
        
        for attempt in {1..30}; do
            if response=$(curl -fsS --max-time 2 http://localhost:8080/hello) &&
               [ "$response" = "Hello World" ]; then
                echo "Deploiement valide : $response"
                exit 0
            fi
            sleep 2
        done
        
        sudo docker logs --tail 50 hello-api
        exit 1
        REMOTE
                    '''
                }
            }
        }
    }
}
