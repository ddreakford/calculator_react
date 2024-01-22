pipeline {
    agent any

    parameters {
        string(name: 'TOKEN', defaultValue: 'sl.agent.token', description: 'Name/key of the SL agent token credential')
        string(name: 'BRANCH', defaultValue: 'master', description: 'The branch to locally clone, build and onboard to SeaLights')
        string(name: 'DOCKER_REPO', defaultValue: 'dwaynedreakford', description: 'Your Docker repo')
        string(name: 'APP_IMAGE_NAME', defaultValue: 'react_calculator', description: 'Name of the image to be deployed')
    }
    environment {
        SL_APP_NAME = "Calculator-React-DD"
        SL_BUILD_NAME = "4.1.${BUILD_NUMBER}_jenkins"
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
                    
                    # Workaround for https://stackoverflow.com/a/69699772
                    export NODE_OPTIONS=--openssl-legacy-provider

                    export PUBLIC_URL="/" && npm run build 
                """
            }
        }

        stage('Install SeaLights agent') {
            steps {
                withCredentials([string(credentialsId: params.TOKEN, variable: 'SL_TOKEN')]) {
                    // Install the SL agent
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

        stage('Create SL Build Session') {
            steps {
                // File, buildSessionId, is written by this step
                sh """
                    # Enable SL agent debugging
                    export NODE_DEBUG=sl-file
                    export SL_LOG_LEVEL=debug

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

        stage('Scan/Instrument JS') {
            steps {
                // Scan the JS and intrument for the browser agent
                sh """
                    # Enable SL agent debugging
                    export NODE_DEBUG=sl-file
                    export SL_LOG_LEVEL=debug

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
        stage('Unit Tests') {
            steps {
                sh """
                    # Enable SL agent debugging
                    export NODE_DEBUG=sl-file
                    export SL_LOG_LEVEL=debug

                    # Open the test stage
                    ./node_modules/.bin/slnodejs start \
                        --tokenfile sealights/sltoken.txt \
                        --buildsessionidfile sealights/buildSessionId \
                        --labid "dd-devjs-laptop" \
                        --testStage "Unit Tests"

                    CI=true npm run test:ci
                    
                    # Upload the coverage report
                    ./node_modules/.bin/slnodejs nycReport \
                        --tokenfile sealights/sltoken.txt \
                        --buildsessionidfile sealights/buildSessionId \
                        --labid "dd-devjs-laptop" \
                        --report coverage/coverage-final.json
                    
                    # Upload test results
                    ./node_modules/.bin/slnodejs uploadReports \
                        --tokenfile sealights/sltoken.txt \
                        --buildsessionidfile sealights/buildSessionId \
                        --labid "dd-devjs-laptop" \
                        --reportFile junit.xml

                    # Close the test stage
                    ./node_modules/.bin/slnodejs end \
                        --tokenfile sealights/sltoken.txt \
                        --buildsessionidfile sealights/buildSessionId \
                        --labid "dd-devjs-laptop" \
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