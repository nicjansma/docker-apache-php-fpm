#!/bin/bash

echo ---
echo apache-php-fpm starting up
echo
echo Loading Apache environment variables...
source /etc/apache2/envvars

#
# apply ENV vars
#

# php-fpm www.conf
echo Modifying php-fpm configuration PHP_FPM_MAX_CHILDREN=$PHP_FPM_MAX_CHILDREN PHP_FPM_START_SERVERS=$PHP_FPM_START_SERVERS PHP_FPM_MIN_SPARE_SERVERS=$PHP_FPM_MIN_SPARE_SERVERS PHP_FPM_MAX_SPARE_SERVERS=$PHP_FPM_MAX_SPARE_SERVERS...
sed -i "s/^pm.max_children = .*$/pm.max_children = ${PHP_FPM_MAX_CHILDREN}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/^pm.start_servers = .*$/pm.start_servers = ${PHP_FPM_START_SERVERS}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/^pm.min_spare_servers = .*$/pm.min_spare_servers = ${PHP_FPM_MIN_SPARE_SERVERS}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/^pm.max_spare_servers = .*$/pm.max_spare_servers = ${PHP_FPM_MAX_SPARE_SERVERS}/" /usr/local/etc/php-fpm.d/www.conf

# php opcache.ini
echo Modifying php opcache configuration PHP_OPCACHE_MEMORY_CONSUMPTION=$PHP_OPCACHE_MEMORY_CONSUMPTION...
sed -i "s/^opcache.memory_consumption=.*$/opcache.memory_consumption=${PHP_OPCACHE_MEMORY_CONSUMPTION}/" /usr/local/etc/php/conf.d/opcache.ini

# php apc.ini
echo Modifying php apc configuration PHP_APC_SHM_SIZE=$PHP_APC_SHM_SIZE...
sed -i "s/^apc.shm_size=.*$/apc.shm_size=${PHP_APC_SHM_SIZE}/" /usr/local/etc/php/conf.d/apc.ini

# php spx.ini
echo Modifying php spx configuration PHP_SPX_HTTP_KEY=$PHP_SPX_HTTP_KEY...
sed -i "s/^spx.http_key =.*$/spx.http_key = \"${PHP_SPX_HTTP_KEY}\"/" /usr/local/etc/php/conf.d/spx.ini

# php xdebug
if [[ "$PHP_XDEBUG_ENABLE" -eq 0 ]]; then
    echo Disabling Xdebug...
    rm -f /usr/local/etc/php/conf.d/xdebug.ini
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi

echo Modifying php xdebug configuration PHP_XDEBUG_TRIGGER=$PHP_XDEBUG_TRIGGER...
sed -i "s/^xdebug.trigger_value=.*$/xdebug.trigger_value=${PHP_XDEBUG_TRIGGER}/" /usr/local/etc/php/conf.d/xdebug.ini

# htpasswd
echo Modifying Apache htpasswd SECRET_HOME_USER=$SECRET_HOME_USER SECRET_HOME_PASS=$SECRET_HOME_PASS...
htpasswd -nb ${SECRET_HOME_USER} ${SECRET_HOME_PASS} > /var/www/secret-home/.htpasswd

# apache secret-home
echo Modifying Apache secret-home APACHE_SECRET_HOME=$APACHE_SECRET_HOME...
echo -e "\nexport APACHE_SECRET_HOME=${APACHE_SECRET_HOME}\n" >> /etc/apache2/envvars

# apache log name
echo Modifying Apache log names APACHE_LOG_NAME=$APACHE_LOG_NAME...
sed -i "s/APACHE_LOG_NAME/${APACHE_LOG_NAME}/g" /etc/supervisor/conf.d/apache-and-php.conf
sed -i "s/APACHE_LOG_NAME/${APACHE_LOG_NAME}/g" /var/www/secret-home/index.html
touch /var/log/php-fpm/php-fpm.php_error_log.$APACHE_LOG_NAME.log
chmod 666 /var/log/php-fpm/*

# ensure supercronic log dir
mkdir -p /var/log/supercronic
chmod 755 /var/log/supercronic

if [[ "$APACHE_DISABLE_COMPRESSION" -eq 1 ]]; then
    echo Modifying Apache to disable compression...
    # disable deflate and brotli
    a2dismod -f deflate

    a2dismod brotli
fi

# msmtp
echo Modifying msmtp MSMTP_HOST=$MSMTP_HOST MSMTP_FROM=$MSMTP_FROM...
sed -i "s/^host .*$/host ${MSMTP_HOST}/" /usr/local/etc/msmtprc
sed -i "s/^from .*$/from ${MSMTP_FROM}/" /usr/local/etc/msmtprc

# redis
echo Modifying Redis REDIS_HOST=$REDIS_HOST
sed -i "s/session.save_path.*/session.save_path = \"${REDIS_HOST}\"/" /usr/local/etc/php/conf.d/redis.ini

# start supervisor
echo Starting supervisor
echo Done with apache-php-fpm startup!
echo ---

/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

