#!/usr/bin/env bash
git checkout "$1"
git pull origin "$1"
git merge "$2"
git push origin "$1"