#!/bin/bash
#
# (c) Copyright 2016 Hewlett Packard Enterprise Development LP
#
# Confidential computer software. Valid license from HP required for
# possession, use or copying. Consistent with FAR 12.211 and 12.212,
# Commercial Computer Software, Computer Software Documentation, and
# Technical Data for Commercial Items are licensed to the U.S. Government
# under vendor's standard commercial license.
#
# validate-copyright-notices.sh REPO
#

# copyright script example

set -eu
set -o pipefail

year=$(date +%Y)

messages=(
    "Copyright [0-9]\{4\},\s*$year Hewlett Packard Enterprise Development LP"
    "Copyright [0-9]\{4\}-$year Hewlett Packard Enterprise Development LP"
    "Copyright $year Hewlett Packard Enterprise Development LP"
    )

repo=$PROJECT
commit=${1:-"HEAD^"}

pushd $repo >/dev/null
pushd $(git rev-parse --show-toplevel) >/dev/null

ignorefile="$PWD/.copyrightignore"

failed=
# Filter the type of files we check, in particular ignore deleted files
files=$(git diff --stat --name-only --diff-filter=AM \
                 --find-renames=100% --find-copies=100% --find-copies-harder \
                 $commit |
    grep -v "$(basename $ignorefile)" | # ignore the ignorefile
    if test -e "$ignorefile"; then
        grep -v -E --file $ignorefile
    else
        cat
    fi || true)
for file in $files ; do
    passed=1
    for message in "${messages[@]}" ; do
        if grep -iq "$message" $file ; then
            passed=
        fi
    done
    if test -n "$passed" ; then
        failed="$file $failed"
    fi
done

if test -n "$failed" ; then
    set +x
    echo "We failed to validate the copyright notices in your review."
    echo "The copyright notice must match one of the following patterns:"
    for message in "${messages[@]}" ; do
        echo " - $message"
    done

    echo
    echo "The files that failed this test are:"
    for file in $failed ; do
        echo " - $file"
    done

    echo
    echo "If there should be no copyright notice on these files. Then you"
    echo "can add this file to .copyrightignore file in the root of your repo."
    exit 1
fi
