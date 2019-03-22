#!/usr/bin/env bash

#
#                              -`
#              ...            .o+`
#           .+++s+   .h`.    `ooo/
#          `+++%++  .h+++   `+oooo:
#          +++o+++ .hhs++. `+oooooo:
#          +s%%so%.hohhoo'  'oooooo+:
#          `+ooohs+h+sh++`/:  ++oooo+:
#           hh+o+hoso+h+`/++++.+++++++:
#            `+h+++h.+ `/++++++++++++++:
#                     `/+++ooooooooooooo/`
#                    ./ooosssso++osssssso+`
#                   .oossssso-````/osssss::`
#                  -osssssso.      :ssss``to.
#                 :osssssss/  Mike  osssl   +
#                /ossssssss/   8a   +sssslb
#              `/ossssso+/:-        -:/+ossss'.-
#             `+sso+:-`                 `.-/+oso:
#            `++:.                           `-/+/
#            .`                                 `/

NAME="$0"
NAME="${NAME##*/}"

DIR=$(readlink -e "$0")
DIR="${DIR%/*}"

UPDATE=0

function help_user() {
    echo ""
    echo "  Extract any given number of compressed files"
    echo ""
    echo "  Usage:"
    echo "      $NAME [OPTIONAL]"
    echo "          Ex."
    echo "          $ $NAME"
    echo ""
    echo "      Optional Flags"
    echo "          -u, --update"
    echo "              Update the repo files (Dockerfile and checkrelease.sh)"
    echo "              create a simple commit with the new version"
    echo "              push the changes"
    echo "          -h, --help"
    echo "              Display help and exit. If you are seeing this, that means that you already know it (nice)"
    echo ""
}

function warn_msg() {
    WARN_MESSAGE="$1"
    printf "[!]     ---- Warning!!! %s \n" "$WARN_MESSAGE"
}

function error_msg() {
    ERROR_MESSAGE="$1"
    printf "[X]     ---- Error!!!   %s \n" "$ERROR_MESSAGE"
}

function status_msg() {
    STATUS_MESSAGGE="$1"
    printf "[*]     ---- %s \n" "$STATUS_MESSAGGE"
}

function check_new_version() {
    local message="$1"
    local nginx_major="$2"
    local nginx_minor="$3"
    local nginx_patch="$4"

    status_msg "$message"

    local nginx_version="${nginx_major}.${nginx_minor}.${nginx_patch}"

    if curl -fsl http://nginx.org/download/nginx-"$nginx_version".tar.gz -o /tmp/nginx.tar.gz
    then
        rm -rf /tmp/nginx.tar.gz
        return 0
    fi

    return 1
}

function update_files() {
    local nginx_new_major="$1"
    local nginx_new_minor="$2"
    local nginx_new_patch="$3"

    status_msg "Updating Dockerfile"
    sed -i "s/${NGINX_MAJOR}.${NGINX_MINOR}.${NGINX_PATCH}/${nginx_new_major}.${nginx_new_minor}.${nginx_new_patch}/" Dockerfile

    status_msg "Updating script"
    sed -i "s/^NGINX_MAJOR=${NGINX_MAJOR}/NGINX_MAJOR=${nginx_new_major}/" checkrelease.sh
    sed -i "s/^NGINX_MINOR=${NGINX_MINOR}/NGINX_MINOR=${nginx_new_minor}/" checkrelease.sh
    sed -i "s/^NGINX_PATCH=${NGINX_PATCH}/NGINX_PATCH=${nginx_new_patch}/" checkrelease.sh

    if hash ntfy 2>/dev/null; then
        NGINX_VERSION="$(grep -E 'ENV\s+NGINX_VERSION\s+[0-9]\.[0-9]+\.[0-9]+' Dockerfile | awk '{print $3}')"
        ntfy -t "New Nginx Version" send "Updating Nginx to ${NGINX_VERSION}"
    fi

    git add checkrelease.sh Dockerfile
    git commit -m "New version ${nginx_new_major}.${nginx_new_minor}.${nginx_new_patch}"
    git tag -m "New version" -a "${nginx_new_major}.${nginx_new_minor}.${nginx_new_patch}"
    git push --follow-tags origin master
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -h|--help)
            help_user
            exit 0
            ;;
        -u|--update)
            UPDATE=1
            ;;
    esac
    shift
done

NGINX_MAJOR=1
NGINX_MINOR=15
NGINX_PATCH=9

NEW_VERSION=0

pushd "$DIR" > /dev/null

if check_new_version  "Checking for major version" "$(( NGINX_MAJOR + 1))" "0" "0"; then
    NEW_VERSION=1
    status_msg "New major version $(( NGINX_MAJOR + 1)).0.0"

    if [[ $UPDATE -eq 1 ]]; then
        update_files "$(( NGINX_MAJOR + 1))" "0" "0"
    fi
    popd > /dev/null
    exit 0
fi

if check_new_version  "Checking for minor version" "$NGINX_MAJOR" "$(( NGINX_MINOR + 1))" "0"; then
    NEW_VERSION=1
    status_msg "New minor version ${NGINX_MAJOR}.$(( NGINX_MINOR + 1)).0"

    if [[ $UPDATE -eq 1 ]]; then
        update_files "${NGINX_MAJOR}" "$(( NGINX_MINOR + 1))" "0"
    fi
    popd > /dev/null
    exit 0
fi


if check_new_version  "Checking for new patches" "$NGINX_MAJOR" "$NGINX_MINOR" "$((NGINX_PATCH + 1))"; then
    NEW_VERSION=1
    status_msg "New patch ${NGINX_MAJOR}.${NGINX_MINOR}.$((NGINX_PATCH + 1))"

    if [[ $UPDATE -eq 1 ]]; then
        update_files "${NGINX_MAJOR}" "${NGINX_MINOR}" "$((NGINX_PATCH + 1))"
    fi
    popd > /dev/null
    exit 0
fi


if [[ $NEW_VERSION -eq 0 ]]; then
    error_msg "No new versions for Nginx yet"
    popd > /dev/null
    exit 1
fi

popd > /dev/null
exit 0
