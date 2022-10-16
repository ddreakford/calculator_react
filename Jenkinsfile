pipeline {
    agent any

    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'The branch to locally clone, build and onboard to SeaLights')
        string(name: 'DOCKER_REPO', defaultValue: 'dwaynedreakford', description: 'Your Docker repo')
        string(name: 'APP_IMAGE_NAME', defaultValue: 'react_calculator', description: 'Name of the image to be deployed')
    }
    environment {
        SL_APP_NAME = "Calculator-React-DD"
        SL_BUILD_NAME = "4.0.${BUILD_NUMBER}"
    }

    stages {
        stage('SCM (Git)') {
            steps {
                cleanWs()
                git branch: "${BRANCH}", url: 'https://github.com/ddreakford/calculator_react.git'
            }
        }

        stage('Build the app') {
            steps {
                sh """
                    npm install
                    export PUBLIC_URL="/" && npm run build 
                """
            }
        }

        stage('Install SeaLights agent') {
            steps {
                withCredentials([string(credentialsId: 'SL_AGENT_TOKEN', variable: 'SL_TOKEN')]) {
                    // Download the agent
                    // Save the agent token in a file
                    sh '''
                        rm -rf sealights && mkdir sealights
                        npm install slnodejs
                        echo $SL_TOKEN > sealights/sltoken.txt
                        ls -l sealights
                    '''
                }
            }
        }

        stage('Create the SL Build Session') {
            steps {
                // File, buildSessionId, is written by this step
                sh """
                    ./node_modules/.bin/slnodejs config \
                        --tokenfile sealights/sltoken.txt \
                        --appname "${SL_APP_NAME}" \
                        --branch "${BRANCH}" \
                        --build "${SL_BUILD_NAME}"
                    mv buildSessionId sealights/
                    ls -l sealights
                """
            }
        }

        stage('Scan/Instrument front end JS') {
            steps {
                // Each module built by gradle will be scanned
                // The build map will be reported to SeaLights
                // Any Unit and Integration tests will be monitored
                sh """
                    ./node_modules/.bin/slnodejs scan --instrumentForBrowsers \
                        --tokenfile sealights/sltoken.txt \
                        --buildsessionidfile sealights/buildSessionId \
                        --labid "dd-devjs-laptop" \
                        --workspacepath build \
                        --outputpath sl_build \
                        --scm git \
                        --es6Modules \
                        --babylonPlugins jsx
                """
            }
        }
        stage('Deploy to QA') {
            steps {
                script {
                    // Create/start a container with SeaLights monitoring
                    String APP_IMAGE_SPEC = "${DOCKER_REPO}/${APP_IMAGE_NAME}:${BUILD_NUMBER}"
                    sh """
                        docker build -f Dockerfile.qa -t ${APP_IMAGE_SPEC} .
                        docker run --name ${APP_IMAGE_NAME} -d -p 8092:8092 ${APP_IMAGE_SPEC}
                    """
                }
            }
        }
    }
}