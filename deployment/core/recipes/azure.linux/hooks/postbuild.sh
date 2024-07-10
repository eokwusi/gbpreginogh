#!/bin/bash

echo "::::::::::::postbuild:::::::::::::"

. $(echo ${BASH_SOURCE[0]%\\*} | awk -F /hooks '{ print $1 }')/lib/helper.sh

# Call custom "postbuild"
  setScope $0
  if [ -f "$SCOPE" ] && [ "$0" != "$SCOPE" ]
  then
    . $(echo $SCOPE)
  fi

echo "::::::::::::::::::::::::::::::::::"