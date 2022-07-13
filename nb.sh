#!/usr/bin/env bash
if [[ $# -eq 0 ]] ; then
    echo 'Error: Branch name is required.'
    exit 1
fi

branch_name=$1
git checkout -b $branch_name
git push --set-upstream origin $branch_name