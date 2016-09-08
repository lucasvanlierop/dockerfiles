#!/bin/bash
set -e

if [ "$#" == 0 ]; then
  cat <<EOT
Usage       : [changed|one <name>] [--push]
  changed     : Only build changed files
  one         : Build a specific application pass application name
  --push      : Push to Docker Hub
EOT
  exit 1
fi

PUSH=false
for i in "$@" ; do
    if [[ $i == "--push" ]] ; then
        PUSH=true
        break
    fi
done

REPO_PREFIX="lucasvanlierop"

validate_diff() {
    if [ "$VALIDATE_UPSTREAM" != "$VALIDATE_HEAD" ]; then
        git diff "$VALIDATE_COMMIT_DIFF" "$@"
    else
        git diff HEAD~ "$@"
    fi
}

function build () {
    local f="$1"
    local image=${f%Dockerfile}
    local base=${image%%\/*}
    local build_dir=$(dirname $(readlink -f $f))
    local dir_name=$(basename ${build_dir})
    local docker_file=`readlink -f $f`
    local version=`grep -P 'ENV VERSION[^\n]*' $docker_file | sed -e 's/ENV VERSION //' || return "0"`
    local variant=
    local tag=

    # Set variant if there is one (e.g. IntelliJ Ultimate is a variant of IntelliJ)
    if [[ "$dir_name" != "$base" ]]; then
        variant="${dir_name}"
    fi

    # Use latest as version if there's not a specific version
    if [[ -z "$version" ]]; then
        version="latest"
    fi

    # Create a tag from variant + version
    if [[ ! -z "$variant" ]]; then
       tag="${variant}-${version}"
    else
       tag="${version}"
    fi

    (
    set -x
    docker build -t $REPO_PREFIX/${base}:${tag} ${build_dir}

    if [[ $PUSH == true ]]; then
        docker push $REPO_PREFIX/${base}:${tag}
    fi
    )

    echo "Successfully built ${base}:${tag} with context ${build_dir}"
}


function build_multiple() {
    local files=$1

    for f in "${files[@]}"; do
        if ! [[ -e "$f" ]]; then
            continue
        fi

        build $f
    done
}

function changed() {
    # this is kind of an expensive check, so let's not do this twice if we
    # are running more than one validate bundlescript
    VALIDATE_REPO="https://github.com/$REPO_PREFIX/dockerfiles.git"
    VALIDATE_BRANCH='master'

    VALIDATE_HEAD="$(git rev-parse --verify HEAD)"

    git fetch -q "$VALIDATE_REPO" "refs/heads/$VALIDATE_BRANCH"
    VALIDATE_UPSTREAM="$(git rev-parse --verify FETCH_HEAD)"

    VALIDATE_COMMIT_DIFF="$VALIDATE_UPSTREAM...$VALIDATE_HEAD"


    # get the dockerfiles changed
    IFS=$'\n'
    files=( $(validate_diff --name-only -- '*Dockerfile') )
    unset IFS

    build_multiple $files
}

function one() {
    local f=$1
    build $f/Dockerfile
}

"$@"

