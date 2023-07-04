#!/bin/sh

set -xeu

for pkg
do
  case "$pkg" in
  *.deb) sudo dpkg --install "$pkg";;
  *.rpm) sudo rpm --install "$pkg";;
  *.tar) tar vxf "$pkg" -C "$TEST_TMPDIR";;
  esac
  (PATH="$PATH:$TEST_TMPDIR/usr/local/bin" exec hello)  # execute in a subshell why not
  case "$pkg" in
  *.deb) sudo dpkg --purge hello;;
  *.rpm) sudo rpm --erase hello;;
  esac
done
