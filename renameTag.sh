#!/usr/bin/env bash
#http://blog.sidmitra.com/how-to-rename-a-tag-already-pushed-to-a-remot
NEW_TAG=$1
OLD_TAG=$2
git tag "$NEW_TAG" "$OLD_TAG"
git push --tags
git push origin :refs/tags/"$OLD_TAG"
git tag -d "$OLD_TAG"