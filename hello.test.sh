#!/bin/bash

set -xeu

for hello
do
  test -x $hello && (exec $hello)  # execute in a subshell why not
done
