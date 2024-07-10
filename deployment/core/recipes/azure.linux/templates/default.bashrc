alias ll='ls -la'
alias wwwroot='cd /home/site/wwwroot'

if [ "$APPSETTING_TYPE" = "drupal" ]
then
  alias drush="/home/site/config/php/bin/php /home/site/wwwroot/vendor/bin/drush --root=/home/site/wwwroot/web --uri=default"
fi

export PATH="/home/site/config/php/bin:$PATH"

echo "Loaded bashrc (/home/.bashrc)"