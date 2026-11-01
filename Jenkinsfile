pipeline {
    agent any
	options {
	    skipDefaultCheckout(true)
        disableConcurrentBuilds()
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

        stage('Prepare Version') {
            steps {
                script {
                    def currentVersion = sh(
                        script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout',
                        returnStdout: true
                    ).trim()

                    if (!(currentVersion ==~ /[0-9]+\.[0-9]+\.[0-9]+-SNAPSHOT/)) {
                        error("Format de version non pris en charge : ${currentVersion}")
                    }

                    def numbers = currentVersion
                        .replace('-SNAPSHOT', '')
                        .tokenize('.')

                    def nextPatch = numbers[2].toInteger() + 1

                    env.NEXT_VERSION =
                        "${numbers[0]}.${numbers[1]}.${nextPatch}-SNAPSHOT"

                    env.IMAGE_NAME =
                        "ellouz/hello-api:${env.NEXT_VERSION}-build-${env.BUILD_NUMBER}"

                    echo "Image a produire : ${env.IMAGE_NAME}"

                    echo "Version actuelle : ${currentVersion}"
                    echo "Prochaine version : ${env.NEXT_VERSION}"
                }
            }
        }

        stage('Update Version') {
            steps {
                sh '''
                    mvn -B versions:set \
                        -DnewVersion="$NEXT_VERSION" \
                        -DgenerateBackupPoms=false
                '''

                sh 'git --no-pager diff -- pom.xml'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn -version'
                sh 'mvn -B clean package'
                sh 'ls -lh target/hello-api.jar'
            }
        }
        stage('Build Image') {
            steps {
                sh 'docker build -t "$IMAGE_NAME" .'
                sh 'docker image ls "$IMAGE_NAME"'
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
        
                        docker push "$IMAGE_NAME"
                    '''
                }
            }
        }
        stage('Deploy EC2') {
            steps {
                sshagent(credentials: ['ec2-server-key']) {
                    sh '''
                        scp -o BatchMode=yes \
                            -o StrictHostKeyChecking=yes \
                            -o ConnectTimeout=10 \
                            docker-compose.yaml \
                            ec2-user@13.60.209.116:/home/ec2-user/hello-stack/docker-compose.yaml

                        ssh -o BatchMode=yes \
                            -o StrictHostKeyChecking=yes \
                            -o ConnectTimeout=10 \
                            ec2-user@13.60.209.116 "bash -se -- '$IMAGE_NAME'" <<'REMOTE'
        set -e
        IMAGE_NAME="$1"
        export IMAGE_NAME
        echo "Image a deployer : $IMAGE_NAME"
        cd /home/ec2-user/hello-stack

        sudo env IMAGE_NAME="$IMAGE_NAME" docker compose config --quiet
        sudo env IMAGE_NAME="$IMAGE_NAME" docker compose pull hello-api
        sudo env IMAGE_NAME="$IMAGE_NAME" docker compose up -d --wait --wait-timeout 120

        sudo env IMAGE_NAME="$IMAGE_NAME" docker compose ps

        for attempt in {1..30}; do
            if response=$(curl -fsS --max-time 2 http://localhost:8080/hello) &&
            [ "$response" = "Hello World" ]; then
                echo "Deploiement Compose valide : $response"
                exit 0
            fi
            sleep 2
        done

        sudo env IMAGE_NAME="$IMAGE_NAME" docker compose logs --tail 50 hello-api
        exit 1
REMOTE
                    '''
                }
            }
        }

        stage('Commit Version') {
            steps {
                sh '''
                    git add pom.xml

                    git -c user.name="Jenkins Learning" \
                        -c user.email="jenkins@localhost" \
                        commit -m "ci: deploy version $NEXT_VERSION [skip ci]"

                    git --no-pager log -1 --oneline
                '''
            }
        }
        stage('Push Version') {
            steps {
                withCredentials([gitUsernamePassword(
                    credentialsId: 'github-token',
                    gitToolName: 'Default'
                )]) {
                    sh '''
                        git fetch origin main

                        if [ "$(git rev-parse FETCH_HEAD)" != "$GIT_COMMIT" ]; then
                            echo "GitHub a change depuis le checkout : push annule."
                            exit 1
                        fi

                        git push origin HEAD:main
                    '''
                }
            }
        }
    }
}
