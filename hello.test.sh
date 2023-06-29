#!/bin/bash

set -xeuo pipefail

for hello
do
  test -x $hello  # expected to be executable
  ($hello)  # execute in a subshell why not
done