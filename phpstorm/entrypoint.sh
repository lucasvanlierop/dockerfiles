#!/usr/bin/env bash

set -e

if [ "$1" = 'dump-logo' ]; then
    base64 /opt/phpstorm/bin/webide.png
    exit 0
fi

# Create a basic user with the same id as the user running starting the container
adduser \
    --no-create-home \
    --disabled-password \
    --gecos '' \
    --uid $LOCAL_UID \
    $LOCAL_USER > /dev/null

# Run PhpStorm as the user created above
su - $LOCAL_USER -c "phpstorm"
