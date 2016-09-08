#!/bin/bash
set -e

DIR=$(readlink -f $(dirname $0))

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
    local path="$1"
    local name=${path%%\/*}
    local context=$(readlink -f $path)
    local context_name=$(basename ${context})
    local dockerfile=`readlink -f $name/Dockerfile`
    local version=`grep -P 'ENV VERSION[^\n]*' $dockerfile | sed -e 's/ENV VERSION //' || return "0"`
    local variant=
    local tag=
    local image_with_tag

    # Set variant if there is one (e.g. IntelliJ Ultimate is a variant of IntelliJ)
    if [[ "$context_name" != "$name" ]]; then
        variant="${context_name}"
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

    image_with_tag="$REPO_PREFIX/${name}:${tag}"
    docker build -t ${image_with_tag} ${context}

    assert_container_dumps_logo $image_with_tag

    if [[ $PUSH == true ]]; then
        docker push ${image_with_tag}
    fi

    echo "Successfully built ${image_with_tag} with context ${context}"
}

function assert_container_dumps_logo() {
    local image_with_tag=$1
    docker run --rm ${image_with_tag} dump-logo | base64 -i --decode > /tmp/logo
    local mime_type=$(grep "$(mimetype -b /tmp/logo)" /etc/mime.types | awk '{print $1}')
    if [[ -z $(echo "${mime_type}" | grep "image/") ]]; then
        echo "Logo is not valid, mimetype was ${mime_type}"
        exit 1
    fi
}

function build_multiple() {
    local applications=$1
    for application in "${applications[@]}"; do
        if ! [[ -e "$application" ]]; then
            continue
        fi

        build "$application"
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

    build_multiple "$(get_changed_applications)"
}

function get_changed_applications() {
    declare changed_application_files
    declare -A local_changed_dirs

    IFS=' ' read -r -a changed_application_files <<< "$(filter_application_files $(get_changed_files))"
    unset IFS

    for f in "${changed_application_files[@]}"; do
        if ! [[ -e "$f" ]]; then
            continue
        fi

        context_name=$(dirname "$f")
        key="$(echo $context_name | sed -e 's#/#-#')"
        local_changed_dirs["key"]="$context_name"
    done

    echo ${local_changed_dirs[@]}
}

function filter_application_files() {
    local changed_files=$1
    echo "$changed_files" | grep -P 'Dockerfile|entrypoint.sh'

}
function get_changed_files() {
    echo $(validate_diff --name-only)
}

function one() {
    local f=$1
    build "$f"
}

"$@"
