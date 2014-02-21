#!/usr/bin/env bash
git checkout "$1"
git pull origin "$1"
git merge "$2"
git add . --all
git push origin "$1"