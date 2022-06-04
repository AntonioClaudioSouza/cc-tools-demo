#!/usr/bin/env bash

# CAUTION: this script will replace every occurrence of the word
# `HLResProject` in the project folder with whatever argument
# you pass. Be very careful.

if [ $# -lt 1 ] ; then
  printf "Usage:\n$ ./renameProject.sh <my-project-name>\n"
  exit
fi

grep -rl HLResProject . --exclude-dir={.git,node_modules} | xargs sed -i s/HLResProject/$1/g
