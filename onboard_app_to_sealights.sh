#!/bin/sh

# An example of onboarding this app to SeaLights.
# This process, except for the prerequisite dryRun run,
# can be automated (see Jenkinsfile).

# The app was created using CRA (Create React App), so
# Jest is used as the unit test runner.
#
# These packages are used to generate the coverage and 
# test results files that are uploaded to SeaLights.
npm install jest-cli
npm install jest-junit

# Install the SeaLights Node.js agent
# (it's used for both front end JS and Node JS)
npm install slnodejs

# Workaround for https://stackoverflow.com/a/69699772
export NODE_OPTIONS=--openssl-legacy-provider

# Build the [React.js] app
#
export PUBLIC_URL="/" && npm run build 

# [PREREQ]
# Run dryRun to identify and fix issues that would inhibit successful 
# onboarding. Detailed results are provided in the folder:
# ./sl-dry-run-output
#
./node_modules/.bin/slnodejs dryRun --verbose --instrumentForBrowsers \
    --workspacepath "./build" \
    --scm git \
    --es6Modules \
    --babylonPlugins jsx

# Optional: Ensure the app works before instrumentation
# npx http-server ./build

# Bring in the agent token
mkdir sealights && cp $AGENT_TOKEN_FILE sealights/

# Enable logging for the SL Node.js agent
export NODE_DEBUG=sl-file
export SL_LOG_LEVEL=info

# If needed to bypass SSL issues...
# export NODE_TLS_REJECT_UNAUTHORIZED=0

# Generate a Build Session ID
export BUILD_TIME=(date +"%y%m%d_%H%M")
./node_modules/.bin/slnodejs config \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --appname "Calculator-React-DD" \
    --branch "master" \
    --build "4.$BUILD_TIME"

# Scan the JS and intrument for the browser agent
./node_modules/.bin/slnodejs scan --instrumentForBrowsers \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop \
    --workspacepath build \
    --outputpath sl_build \
    --scm git \
    --es6Modules \
    --babylonPlugins jsx

# Optional: Review the list of instrumented files
# diff -qr build sl_build

# -------------------------------------
# Unit Tests
# -------------------------------------

# Open the test stage
./node_modules/.bin/slnodejs start \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop \
    --testStage "Unit Tests"

# Run the unit tests
CI=true npm run test:ci

# Upload coverage report
./node_modules/.bin/slnodejs nycReport \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop \
    --report coverage/coverage-final.json

# Upload test results
./node_modules/.bin/slnodejs uploadReports \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop \
    --reportFile junit.xml

# End the test stage
./node_modules/.bin/slnodejs end \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop

# Deploy the instrumented JS for other test stages
# (Either start with instrumented version, or replace
# normally distributed files with instrumented files)
http-server ./sl_build

