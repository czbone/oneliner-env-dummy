#!/bin/bash
# 
# Script Name: start.sh
#
# Version:      5.0.0
# Author:       Naoki Hirata
# Date:         2024-07-03
# Usage:        start.sh [-test]
# Options:      -test      test mode execution with the latest source package
# Description:  This script builds server environment with the one-liner command.
# Version History:
#               5.0.0  (2024-07-03) renewal release
# License:      MIT License

# Define macro parameter
readonly GITHUB_USER="czbone"
readonly GITHUB_REPO="oneliner-env-dummy"
readonly WORK_DIR=/root/${GITHUB_REPO}_work
readonly PLAYBOOK="lemp"
readonly LOCAL_ANSIBLE_BIN=/root/.local/bin
readonly INSTALL_PACKAGE_CMD="apt -y install"

# check root user
readonly USERID=`id | sed 's/uid=\([0-9]*\)(.*/\1/'`
echo $USERID;
if [ $USERID -ne 0 ]
then
    echo "error: can only excute by root"
    exit 1
fi

# Check os version
declare OS="unsupported os"
declare DIST_NAME=""

if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    RELEASE_FILE=/etc/os-release
    if grep '^NAME="CentOS' ${RELEASE_FILE} >/dev/null; then
        OS="CentOS"
        #DIST_NAME="CentOS"
    elif grep '^NAME="Ubuntu' ${RELEASE_FILE} >/dev/null; then
        OS="Ubuntu"
        DIST_NAME="Ubuntu"
    fi
fi

# Exit if unsupported os
if [ "${DIST_NAME}" == '' ]; then
    echo "Your platform is not supported."
    uname -a
    exit 1
fi

echo "########################################################################"
echo "# $DIST_NAME"
echo "# START BUILDING ENVIRONMENT"
echo "########################################################################"

# Get test mode
if [ "$1" == '-test' ]; then
    readonly TEST_MODE=true

    echo "################# START TEST MODE #################"
else
    readonly TEST_MODE=false
fi

# Install ansible command
if ! type -P ansible >/dev/null ; then
    ${INSTALL_PACKAGE_CMD} software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    ${INSTALL_PACKAGE_CMD} ansible-core
fi

# Install git command
${INSTALL_PACKAGE_CMD} git

# Download the latest repository archive
if ${TEST_MODE}; then
    url="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/master.tar.gz"
    version="new"
else
    url=`curl -s "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/tags" | grep "tarball_url" | \
        sed -n '/[ \t]*"tarball_url"/p' | head -n 1 | \
        sed -e 's/[ \t]*".*":[ \t]*"\(.*\)".*/\1/'`
    version=`basename $url | sed -e 's/v\([0-9\.]*\)/\1/'`
fi
filename=${GITHUB_REPO}_${version}.tar.gz
filepath=${WORK_DIR}/$filename

# Set current directory
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}
savefilelist=`ls -1`

# Download archived repository
echo "########################################################################"
echo "Start download GitHub repository ${GITHUB_USER}/${GITHUB_REPO}" 
curl -s -o ${filepath} -L $url

# Remove old files
for file in $savefilelist; do
    if [ ${file} != ${filename} ]
    then
        rm -rf "${file}"
    fi
done

# Get archive directory name
destdir=`tar tzf ${filepath} | head -n 1`
destdirname=`basename $destdir`

# Unarchive repository
tar xzf ${filename}
find ./ -type f -name ".gitkeep" -delete
mv ${destdirname} ${GITHUB_REPO}
echo ${filename}" unarchived"

# launch ansible
cd ${WORK_DIR}/${GITHUB_REPO}/playbooks/${PLAYBOOK}
ansible-galaxy install --role-file=requirements.yml
ansible-playbook -i localhost, main.yml
