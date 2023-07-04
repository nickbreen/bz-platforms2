#!/bin/sh

set -xeu

for hello
do
  (PATH=$PATH:$(dirname $hello) exec hello)  # execute in a subshell why not
done
