#!/usr/bin/env bash
branch_name=$(git symbolic-ref --short HEAD)
default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
remote_exists="$(git ls-remote --heads origin $branch_name | wc -l)"

git checkout $default_branch
git fetch
git pull

if [[ $remote_exists -eq 1 ]] ; then
    echo "Deleting remote branch $branch_name."
    git push origin --delete $branch_name
else
	echo "Remote branch $branch_name does not exist."
fi

echo "Deleting local branch $branch_name"
git branch -D $branch_name
