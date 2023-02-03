#!/bin/bash

PROJECT="obs_scm_demo"
REMOTE="origin"
BRANCH="main"
# If your tag looks like "v0.0.3", do nothing.
# If your tag looks like "cvetool-v0.0.3", set TAG_PREFIX="cvetool-"
TAG_PREFIX=""

# credit: https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
function __trim {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

function _first_letter_lower_case {
    local user_input="$1"
    local retval
    retval="$(__trim "$user_input")"
    retval="${retval,,}"
    retval="${retval:0:1}"
    echo "$retval"
}

function does_that_look_sane {
    local agree
    echo -n "Does that look sane? (y/ENTER, n/CTRL-c) "
    read -r agree
    if [ "$agree" ] ; then
        agree="$(_first_letter_lower_case "$agree")"
        if [ "$agree" = "n" ] ; then
            error_exit "OK. Have a nice day!"
        fi
    fi
    echo
}

function error_exit {
    echo >&2 "$1"
    exit 1
}

MOST_RECENT_TAG="$(git describe --tags --abbrev=0 --match "${TAG_PREFIX}v*")"
# if TAG_PREFIX includes "-" character, the cut options will need to be tweaked!
MOST_RECENT_TAG_CLIPPED="$(echo "$MOST_RECENT_TAG" | cut -d- -f1)"
VERSION="${MOST_RECENT_TAG_CLIPPED#v}"

echo "The current version number appears to be ->$VERSION<-"
does_that_look_sane

IFS=. read -r MAJOR MINOR POINT <<< "$VERSION"
POINT="$((POINT + 1))"
INCREMENTED_VERSION="${MAJOR}.${MINOR}.${POINT}"

echo "Hit ENTER to increment the version number to ->$INCREMENTED_VERSION<- or"
echo -n "type in the new version number to use: "
read -r new_version_number
if [ "$new_version_number" ] ; then
    INCREMENTED_VERSION="$new_version_number"
    if [[ $new_version_number =~ ^([0-9]\.)+[0-9] ]] ; then
        INCREMENTED_VERSION="$new_version_number"
    else
        error_exit "You entered ->$new_version_number<- but that does not look like a version number!"
    fi
fi
echo "Will increment the version to $INCREMENTED_VERSION"

TMP_FILE="$(mktemp)"
set -x
git --no-pager log --reverse --no-merges --pretty=format:%s "$MOST_RECENT_TAG..HEAD" > "$TMP_FILE"
set +x
COMMITS_IN_RELEASE="$(cat "$TMP_FILE")"

if [ "$COMMITS_IN_RELEASE" ] ; then
    sed -i -e 's/^/  + /' "$TMP_FILE"
else
    echo "ERROR: Nothing to release."
    error_exit "Commit something and try again?"
fi

SAVED_CHANGES="$(mktemp)"
cp "$PROJECT.changes" "$SAVED_CHANGES"
osc vc -m"Update to version $INCREMENTED_VERSION:
$(cat "$TMP_FILE")"
sed -i -e "2{s/$/& - $INCREMENTED_VERSION/}" $PROJECT.changes
vim "$PROJECT.changes"

set -x
diff "$SAVED_CHANGES" "$PROJECT.changes"
set +x

echo "Are you ready to release $INCREMENTED_VERSION with this changes file entry?"
echo "NOTE: this includes creating a tag and pushing to the remote!"
while [ -z "$commit" ] ; do
    echo -n "(y/n) "
    read -r commit
    if [ "$commit" ] ; then
        commit="$(_first_letter_lower_case "$commit")"
        if [ "$commit" = "y" ] ; then
            break
        else
            echo "OK. The original changes file has been saved to $SAVED_CHANGES"
            error_exit "Have a nice day!"
        fi
    fi
done

echo "Releasing version $INCREMENTED_VERSION !!!"
set -x
echo "$INCREMENTED_VERSION" > VERSION
git commit -a -s -m"Bump to version $INCREMENTED_VERSION"
git tag "${TAG_PREFIX}v$INCREMENTED_VERSION"
git push --atomic "$REMOTE" "$BRANCH" "${TAG_PREFIX}v$INCREMENTED_VERSION"
set +x
