#!/bin/bash

set -xeuo pipefail

for c in ${1-executors/*/*/Containerfile}
do
  IFS=/ read prefix d tag containerfile <<< "$c"
  #docker build --tag $prefix/$d:$tag --file $prefix/$d/$tag/$containerfile $prefix/$d/$tag
  #docker run --rm $prefix/$d:$tag gcc -E -xc - -v | tee $c.includes || :
  docker run --rm $prefix/$d:$tag rpm -q glibc gcc || docker run --rm $prefix/$d:$tag dpkg -l libc6 gcc
done
