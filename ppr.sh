#!/usr/bin/env bash
branch_name=$(git symbolic-ref --short HEAD)
default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
#echo $branch_name
git checkout $default_branch
git fetch
git pull
git push origin --delete $branch_name
git branch -D $branch_name
