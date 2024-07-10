#!/bin/bash

echo "::::::::::::postdeploy::::::::::::"

# Load helper
  if [ -f "$DEPLOYMENT_SOURCE/deployment/core/recipes/azure.linux/lib/helper.sh" ]
  then
    . $DEPLOYMENT_SOURCE/deployment/core/recipes/azure.linux/lib/helper.sh
  fi

# Remove deployment code
  if [ -d "$DEPLOYMENT_TARGET/deployment" ]
  then
    rm -r $DEPLOYMENT_TARGET/deployment
    checkCommand "Removed directory: \"$DEPLOYMENT_TARGET/deployment\"" "Could not remove directory: \"$DEPLOYMENT_TARGET/deployment\""
  fi

# Environment files
  if [ -f "$DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/robots.txt" ]
  then
    TARGET_FILE_PATH="$DEPLOYMENT_TARGET/robots.txt"
    if [ "$APPSETTING_SITE_DIRECTORY" != "" ]
    then
      TARGET_FILE_PATH="$DEPLOYMENT_TARGET/$APPSETTING_SITE_DIRECTORY/robots.txt"
    fi
    cp $DEPLOYMENT_CUSTOM_PATH/env/$APPSETTING_ENV/robots.txt $TARGET_FILE_PATH
    checkCommand "Setting file: \"$TARGET_FILE_PATH\"" "Could not set file: \"$TARGET_FILE_PATH\""
  fi

# Install dependencies
  if [ -f "$DEPLOYMENT_TARGET/package.json" ] && [ "$APPSETTING_NPM_RUN_SCRIPT" != "" ]
  then
      echo "Setting dependencies from \"$DEPLOYMENT_TARGET/package.json\"..."
      cd $DEPLOYMENT_TARGET
      npm install --loglevel=error
      checkCommand "Installed dependencies from \"$DEPLOYMENT_TARGET/package.json\"" "Could not install dependencies from \"$DEPLOYMENT_TARGET/package.json\""
      npm run $APPSETTING_NPM_RUN_SCRIPT --loglevel=error
      checkCommand "Executed \"npm run $APPSETTING_NPM_RUN_SCRIPT --loglevel=error\"" "Could not execute: \"npm run $APPSETTING_NPM_RUN_SCRIPT --loglevel=error\""
  fi
  
# Execute drupal actions
  if [ "$APPSETTING_TYPE" = "drupal" ]
  then
    if [ -f "$HOME/.bashrc" ]
    then
      source "$HOME/.bashrc"
    fi
    DEPLOYMENT_DRUSH_CMD="$HOME/site/config/php/bin/php /home/site/wwwroot/vendor/bin/drush"
    cd $DEPLOYMENT_TARGET
    # echo "Enabling maintenance mode..."
    # $DEPLOYMENT_DRUSH_CMD state:set system.maintenance_mode 1
    echo "Updating database..."
    $DEPLOYMENT_DRUSH_CMD updb -y
    echo "Importing configuration site changes from data folder..."
    $DEPLOYMENT_DRUSH_CMD cim -y
    # echo "Disabling maintenance mode..."
    # $DEPLOYMENT_DRUSH_CMD state:set system.maintenance_mode 0
    echo "Rebuilding cache..."
    $DEPLOYMENT_DRUSH_CMD cr
  fi

# Call custom "postdeploy"
  setScope $0
  if [ -f "$SCOPE" ] && [ "$0" != "$SCOPE" ] && [ -f "$DEPLOYMENT_SOURCE/deployment/core/recipes/azure.linux/lib/helper.sh" ]
  then
    . $(echo $SCOPE)
  fi

echo "::::::::::::::::::::::::::::::::::"