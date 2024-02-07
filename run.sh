#!/bin/bash

# bash file to run pipeline
# it checks the make.lock file to avoid running the process twice.

cleanup() {
  rm -f make.lock
}

set -e

if [ -e make.lock ]; then
  echo "Skip start: pipeline is already running."
  exit 1
fi

touch make.lock
# remove make.lock and exit after the pipeline finish
trap 'cleanup' EXIT

make update_db
make clean
make -j16
make upload
