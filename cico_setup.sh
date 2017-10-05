#!/bin/bash -ex

load_jenkins_vars() {
    if [ -e "jenkins-env" ]; then
        cat jenkins-env \
          | grep -E "(DEVSHIFT_TAG_LEN|DEVSHIFT_USERNAME|DEVSHIFT_PASSWORD|JENKINS_URL|GIT_BRANCH|GIT_COMMIT|BUILD_NUMBER|ghprbSourceBranch|ghprbActualCommit|BUILD_URL|ghprbPullId)=" \
          | sed 's/^/export /g' \
          > ~/.jenkins-env
        source ~/.jenkins-env
    fi
}

prep() {
    yum -y update
    yum -y install git gcc-c++ bzip2 fontconfig initscripts
    yum -y install gtk2 libXtst libXScrnSaver libXScrnSaver-devel GConf2
    yum -y install firefox Xvfb libXfont libsecret
    export CXX="g++-4.9" CC="gcc-4.9" DISPLAY=:99.0;
    /usr/bin/Xvfb :99 -screen 0 1280x1024x24 &
    sleep 3;
    curl -sL https://rpm.nodesource.com/setup_6.x | sudo -E bash -
    yum -y install nodejs
}

install_dependencies() {
    # Build fabric8-analytics-vscode-extension
    npm install -g typescript
    npm install -g vsce
    npm install -g rimraf
    rimraf node_modules
    npm install;
    #chmod +x /root/payload/node_modules/phantomjs-prebuilt/lib/phantom/bin/phantomjs

    if [ $? -eq 0 ]; then
        echo 'CICO: npm install : OK'
    else
        echo 'CICO: npm install : FAIL'
        exit 1
    fi
}

# run_unit_tests() {
#     # Exec unit tests
#     npm run test:unit

#     if [ $? -eq 0 ]; then
#         echo 'CICO: unit tests OK'
#     else
#         echo 'CICO: unit tests FAIL'
#         exit 2
#     fi
# }

build_project() {
    npm run postinstall
    npm run build
    npm run vscode:prepublish
    vsce package

    if [ $? -eq 0 ]; then
        echo 'CICO: vsce prepublish OK'
    else
        echo 'CICO: vsce prepublish FAIL'
        exit 2
    fi
}

run_int_tests() {
    # Exec integration tests
    npm test --silent

    if [ $? -eq 0 ]; then
        echo 'CICO: integration tests OK'
    else
        echo 'CICO: integration tests FAIL'
        exit 2
    fi
}

load_jenkins_vars
prep