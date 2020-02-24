#!/bin/sh

# docker cloud repo
REPO_ACCOUNT="mitzerh"
REPO_NAME="apollo-php"
REPO_TAG="latest"
if [ -n "$1" ]; then
    REPO_TAG="$1"
fi

TAG_OK=$(git tag | grep $REPO_TAG)

if [ -n "${TAG_OK}" ]; then
    git checkout $REPO_TAG
    docker build -t ${REPO_ACCOUNT}/${REPO_NAME}:${REPO_TAG} .
    git checkout master
fi
