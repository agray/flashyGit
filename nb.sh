#!/usr/bin/env bash
branch_name=$1
git checkout -b $branch_name
git push --set-upstream origin $branch_name