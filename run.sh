#!/bin/bash -l

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

if [ -z "$FTPUSER" ] ; then   echo "FTPUSER env variable is not defined" ; exit 1; fi
if [ -z "$FTPPASSWORD" ] ; then   echo "FTPPASSWORD env variable is not defined" ; exit 1; fi
if [ -z "$PGUSER" ] ; then   echo "FTPUSER env variable is not defined" ; exit 1; fi
if [ -z "$PGPASSWORD" ] ; then   echo "FTPPASSWORD env variable is not defined" ; exit 1; fi

touch make.lock
# remove make.lock and exit after the pipeline finish
trap 'cleanup' EXIT

echo $(date -u) "start process"
echo "update db"
make update_db

echo "rerun the pipeline"
make clean
make -j16

echo "upload"
make upload

echo $(date -u) "all done"

