#!/bin/sh

# An example of onboarding this app to SeaLights.
# This process, except for the prerequisite dryRun run,
# can be automated (see Jenkinsfile).

# Install the SeaLights Node.js agent. 
# This is used for both front end JS and Node JS.
npm install slnodejs

# [PREREQ]
# Run dryRun to identify and fix issues that would inhibit successful 
# onboarding.
./node_modules/.bin/slnodejs dryRun --verbose --instrumentForBrowsers \
    --workspacepath "./build" \
    --scm git \
    --es6Modules \
    --babylonPlugins jsx

# Build the [React.js] app
#
export PUBLIC_URL="/" && npm run build 

# Optional: Ensure the app works before instrumentation
# http-server ./build

# Bring in the agent token
mkdir sealights && cp $AGENT_TOKEN_FILE sealights/

# Generate a session id
export BUILD_TIME=`date +"%y%m%d_%H%M"`
./node_modules/.bin/slnodejs config \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --appname "Calculator-React-DD" \
    --branch "master" \
    --build "3.$BUILD_TIME"

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

# Deploy the instrumented JS for testing
# Optional: Replace original build with instrumented version
#
# mv build build_original
# mv sl_build build
# http-server ./build

# Start the app
http-server ./sl_build

# Open a test stage
./node_modules/.bin/slnodejs start \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop \
    --teststage "Manual Tests"

# Report each test 
# ...

# Close a test stage
./node_modules/.bin/slnodejs end \
    --tokenfile sealights/sltoken-dev-cs.txt \
    --buildsessionidfile buildSessionId \
    --labid dd-devjs-laptop












