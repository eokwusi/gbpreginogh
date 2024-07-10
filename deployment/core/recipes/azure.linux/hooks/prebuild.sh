#!/bin/bash

echo ":::::::::::::prebuild:::::::::::::"

# Load helper
  . $(echo ${BASH_SOURCE[0]%\\*} | awk -F /hooks '{ print $1 }')/lib/helper.sh

# Setting directories...
  DIRECTORIES="/home/site/config /home/site/config/php/bin /home/site/config/php/ext /home/site/config/php/ini"
  for DIR in $(echo $DIRECTORIES | xargs -n1); do 
    if [ ! -d "$DIR" ]
    then
      mkdir -p "$DIR"
      checkCommand "Setting directory: \"$DIR\"" "Could not set directory: \"$DIR\""
    fi
  done
  if [ "$APPSETTING_FILE_PRIVATE_PATH" != "" ] && [ ! -d "$APPSETTING_FILE_PRIVATE_PATH" ]
  then
    mkdir -p "$APPSETTING_FILE_PRIVATE_PATH"
    checkCommand "Setting directory: \"$APPSETTING_FILE_PRIVATE_PATH\"" "Could not set directory: \"$APPSETTING_FILE_PRIVATE_PATH\""
  fi

# Setting postdeploy script
  if [ ! -d "$HOME/site/deployments/tools/PostDeploymentActions/" ]
  then
    mkdir -p "$HOME/site/deployments/tools/PostDeploymentActions/"
    checkCommand "Setting directory: \"$HOME/site/deployments/tools/PostDeploymentActions/\"" "Could not set directory: \"$HOME/site/deployments/tools/PostDeploymentActions/\""
  fi
  setScope $DEPLOYMENT_RECIPE_PATH/hooks/postdeploy.sh $HOME/site/deployments/tools/PostDeploymentActions/postdeploy.sh

# Setting scopes...
  setScope "$DEPLOYMENT_RECIPE_PATH/templates/default.bashrc" "$HOME/.bashrc"
  setScope "$DEPLOYMENT_RECIPE_PATH/templates/default.profile" "$HOME/.profile"
  if [ "$DEPLOYMENT_PHP_VERSION" = "8" ]
  then
    setScope "$DEPLOYMENT_RECIPE_PATH/templates/default.startup" "$HOME/site/config/startup.sh"
    if [ -f "$DEPLOYMENT_RECIPE_PATH/templates/$APPSETTING_TYPE.nginx.conf" ]
    then
      setScope "$DEPLOYMENT_RECIPE_PATH/templates/$APPSETTING_TYPE.nginx.conf" "$HOME/site/config/nginx.conf"
    else
      setScope "$DEPLOYMENT_RECIPE_PATH/templates/default.nginx.conf" "$HOME/site/config/nginx.conf"
    fi
  fi
  setScope "$DEPLOYMENT_RECIPE_PATH/bin/$PHP_VERSION/php" "$HOME/site/config/php/bin/php"
  setScope "$DEPLOYMENT_RECIPE_PATH/templates/directives.ini" "$HOME/site/config/php/ini/directives.ini"

# Setting extensions...
  OUTPUT_EXTENSIONS_FILE=""
  # Common
  if [ -d "$DEPLOYMENT_RECIPE_PATH/extensions/$PHP_VERSION" ]
  then
    for FILE in $(find $DEPLOYMENT_RECIPE_PATH/extensions/$PHP_VERSION -type f -name "*.so"); do 
      EXTENSION_NAME=$(basename $FILE)
      setScope $FILE $HOME/site/config/php/ext/$EXTENSION_NAME
      OUTPUT_EXTENSIONS_FILE="$OUTPUT_EXTENSIONS_FILE extension=$HOME/site/config/php/ext/$EXTENSION_NAME"
    done
  fi
  # Custom all environments
  if [ -d "$DEPLOYMENT_CUSTOM_PATH/all/extensions/$PHP_VERSION" ]
  then
    for FILE in $(find $DEPLOYMENT_CUSTOM_PATH/all/extensions/$PHP_VERSION -type f -name "*.so"); do 
      EXTENSION_NAME=$(basename $FILE)
      setScope $FILE $HOME/site/config/php/ext/$EXTENSION_NAME
      OUTPUT_EXTENSIONS_FILE="$OUTPUT_EXTENSIONS_FILE extension=$HOME/site/config/php/ext/$EXTENSION_NAME"
    done
  fi
  # Custom environment
  if [ -d "$DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/extensions/$PHP_VERSION" ]
  then
    for FILE in $(find $DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/extensions/$PHP_VERSION -type f -name "*.so"); do
      EXTENSION_NAME=$(basename $FILE)
      setScope $FILE $HOME/site/config/php/ext/$EXTENSION_NAME
      OUTPUT_EXTENSIONS_FILE="$OUTPUT_EXTENSIONS_FILE extension=$HOME/site/config/php/ext/$EXTENSION_NAME"
    done
  fi
  # Check extensions file
  if [ "$OUTPUT_EXTENSIONS_FILE" != "" ]
  then
    EXTENSIONS_FILE="$HOME/site/config/php/ini/extensions.ini"
    echo "$OUTPUT_EXTENSIONS_FILE" | xargs -n1 > $EXTENSIONS_FILE
    checkCommand "Setting file: \"$EXTENSIONS_FILE\"" "Could not set file: \"$EXTENSIONS_FILE\""
  else
    echo "SUCCESS: No extensions found"
  fi

# Call custom "prebuild"
  setScope $0
  if [ -f "$SCOPE" ] && [ "$0" != "$SCOPE" ]
  then
    . $(echo $SCOPE)
  fi

echo "::::::::::::::::::::::::::::::::::"

