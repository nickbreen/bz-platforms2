#!/bin/sh

set -xeu

# Use a valid shell syntax so it blows up informatively if run
exec ${test?} ${args?}
