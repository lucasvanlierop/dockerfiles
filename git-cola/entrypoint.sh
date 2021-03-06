#!/usr/bin/env bash

set -e

COMMAND="$@"

function dump-logo() {
    base64 /usr/share/git-cola/icons/git.svg
    exit 0
}

function start(){
    # Create a basic user with the same id as the user running starting the container
    adduser \
        --no-create-home \
        --disabled-password \
        --gecos '' \
        --uid $LOCAL_UID \
        $LOCAL_USER > /dev/null

    # Run as the user created above
    su - $LOCAL_USER -c git-cola
}

$COMMAND
