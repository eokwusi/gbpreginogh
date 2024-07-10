#!/bin/bash

# Helper funcions
  success() {
    echo "SUCCESS: $1"
  }
  export -f success

  warning() {
    echo "WARNING: $1"
  }
  export -f warning

  error() {
    echo "ERROR: $1"
  }
  export -f error

  throwException () {
    echo
    error "$1"
    echo "An error has occurred during web site deployment."
    echo
    exit 1
  }
  export -f throwException

  checkCommand () {
    if [ ! $? -eq 0 ]; then
      throwException "$2"
    else
      if [ "$3" = "" ]
      then
        echo -e "SUCCESS: $1"
      else 
        echo -e 'SUCCESS: '$1' \n\t\t\t |=> to ... '$3
      fi
    fi
  }
  export -f checkCommand

  initializeComposerConfig() {
    if [ ! -e "$COMPOSER_ARGS" ]; then
      COMPOSER_ARGS="--no-interaction --prefer-dist --optimize-autoloader --no-progress --no-dev --verbose"
    fi
  }
  export -f initializeComposerConfig

  setScope () {
    SCOPE=""
    if [ -f "$1" ]
    then
      SCOPE_FILENAME=$(basename $1)
      SCOPE_TYPE=$(echo $(dirname $1) | awk -F \/ '{ print $NF }')
      # 1º.
      if [ -f "$DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/$SCOPE_TYPE/$SCOPE_FILENAME" ]
      then
        SCOPE="$DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/$SCOPE_TYPE/$SCOPE_FILENAME"
      else 
        # 2º. 
        if [ -f "$DEPLOYMENT_CUSTOM_PATH/all/$SCOPE_TYPE/$SCOPE_FILENAME" ]
        then
          SCOPE="$DEPLOYMENT_CUSTOM_PATH/all/$SCOPE_TYPE/$SCOPE_FILENAME"
        else 
          SCOPE="$1"
        fi
      fi
    fi
    if  [ "$SCOPE" != "" ]
    then
      if [ "$2" != "" ]
      then
        cp $SCOPE $2
        checkCommand "Setting scope: \"$(echo $SCOPE | awk -F $DEPLOYMENT_SOURCE/ '{ print $2 }')\"" "Could not set scope: \"$(echo $SCOPE | awk -F $DEPLOYMENT_SOURCE/ '{ print $2 }')\"" "$2"
      fi
    else 
      throwException "Could not set scope from: $1"
    fi
  }
  export -f setScope


# Environment Variables
  SCRIPT_DIR="${BASH_SOURCE[0]%\\*}"
  SCRIPT_DIR="${SCRIPT_DIR%/*}"
  ARTIFACTS=$SCRIPT_DIR/../artifacts

  if [[ ! -n "$DEPLOYMENT_SOURCE" ]]; then
    export DEPLOYMENT_SOURCE=$SCRIPT_DIR
  fi
  if [[ ! -n "$DEPLOYMENT_TARGET" ]]; then
    export DEPLOYMENT_TARGET=$ARTIFACTS/wwwroot
  fi

  export DEPLOYMENT_CUSTOM_PATH="$DEPLOYMENT_SOURCE/deployment/custom"
  export DEPLOYMENT_RECIPE_PATH="$(echo $SCRIPT_DIR | awk -F /lib '{ print $1 }')"
  export DEPLOYMENT_STACK="$(echo $DEPLOYMENT_RECIPE_PATH | awk -F\/ '{ print $NF }')"
  if [ "$(echo $PHP_VERSION | grep "^7")" != "" ]
  then 
    export DEPLOYMENT_PHP_VERSION="7"
  fi
  if [ "$(echo $PHP_VERSION | grep "^8")" != "" ]
  then 
    export DEPLOYMENT_PHP_VERSION="8"
  fi
  if [ "$APPSETTING_TYPE" = "" ]
  then
    APPSETTING_TYPE="default"
  fi