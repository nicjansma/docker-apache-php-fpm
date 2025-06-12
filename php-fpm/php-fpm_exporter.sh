#!/bin/bash
source /etc/apache2/envvars

export PHP_FPM_SCRAPE_URI="unix:///run/php-fpm-www.sock;${APACHE_SECRET_HOME}/php-fpm-status"
export PHP_FPM_FIX_PROCESS_COUNT=true

/usr/bin/php-fpm_exporter server