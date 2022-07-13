#!/usr/bin/env bash
branch_name=$(git symbolic-ref --short HEAD)
default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

if [[ `git status --porcelain` ]]; then
  echo 'You have pending changes locally, commit them to your branch first.'
  exit 1
fi

git checkout $default_branch
git pull
git checkout $branch_name
git merge origin $default_branch