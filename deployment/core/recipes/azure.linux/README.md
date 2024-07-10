# azure.linux

Ref: https://azureossd.github.io/2019/01/29/azure-app-service-linux-adding-php-extensions/


## PHP

php -v

pear config-show

ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20220829/
ls -la /usr/local/lib/php/extensions/no-debug-non-zts-20220829/ | grep redis


* OJO!. No cargan las mismas extensiones de PHP estando como "root" que como "kudu_ssh_user"

  php -m | grep mysql && php -m | grep redis


- Copia la extension a "/home/site/config/php/ext" 

  cp /usr/local/lib/php/extensions/no-debug-non-zts-20220829/pdo_mysql.so /home/site/config/php/ext/
  cp /usr/local/lib/php/extensions/no-debug-non-zts-20220829/redis.so /home/site/config/php/ext

- Añadela en el fichero "/home/site/config/php/ini/extensions.ini"

  extension=/home/site/config/php/ext/pdo_mysql.so
  extension=/home/site/config/php/ext/redis.so
  extension=/home/site/config/php/ext/gd.so


## COMPOSER

/tmp/oryx/platforms/php-composer/2.3.4/composer.phar install --no-interaction