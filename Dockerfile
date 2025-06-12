# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

ARG PHP_VERSION="7.2"

# Start from php-fpm
FROM php:${PHP_VERSION}-fpm

#
# Arguments (build)
#

# linux packages to install
ARG RUNTIME_PACKAGE_DEPS="apache2 bash curl iputils-ping less libcurl4 libssh2-1 mariadb-client msmtp-mta nano rsync ssh sudo supervisor telnet unzip wget zstd"

# linux packages to add during build (only)
ARG BUILD_PACKAGE_DEPS="libcurl4-openssl-dev libjpeg-dev libpng-dev libssh2-1-dev libxml2-dev"

# PHP extensions
ARG PHP_EXT_DEPS="apcu bcmath brotli bz2 calendar curl dba exif gd gettext gmp imagick intl json ldap luasandbox mbstring mongodb mysqli opcache pdo_mysql redis shmop snmp soap sockets ssh2 vips xdebug xml xmlrpc xsl zip zstd"

#
# Build repo
#

# add install-php-extensions
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# install dependencies and cleanup in one step
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        $RUNTIME_PACKAGE_DEPS \
        $BUILD_PACKAGE_DEPS \
    && install-php-extensions $PHP_EXT_DEPS \
    && apt-get clean \
    && apt-get autoremove -y \
    && apt-get purge -y --auto-remove $BUILD_PACKAGE_DEPS \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /var/log/dpkg.log

#
# Change user of www-data to :502
#
RUN groupmod -g 502 www-data
RUN usermod -u 502 -g 502 www-data
RUN chown www-data:www-data /var/www/html

#
# Apache 
#
COPY apache/apache2.conf /etc/apache2/apache2.conf
COPY apache/httpd-site.conf /etc/apache2/sites-available/000-default.conf

COPY apache/conf-available/* /etc/apache2/conf-available/
COPY apache/mods-available/* /etc/apache2/mods-available/

COPY --chmod=755 ./apache/apache2-start.sh /root/apache2-start.sh

# enable/disable mods & confis
RUN    a2enmod proxy_fcgi \
    && a2enmod actions \
    && a2enmod allowmethods \
    && a2enmod autoindex \
    && a2enmod brotli \
    && a2enmod cgi \
    && a2enmod data \
    && a2enmod dir \
    && a2enmod expires \
    && a2enmod headers \
    && a2enmod http2 \
    && a2enmod include \
    && a2enmod info \
    && a2enmod macro \
    && a2enmod mime \
    && a2enmod mime_magic \
    && a2enmod proxy_connect \
    && a2enmod proxy_http \
    && a2enmod proxy_http2 \
    && a2enmod remoteip \
    && a2enmod rewrite \
    && a2disconf localized-error-pages \
    && a2disconf other-vhosts-access-log \
    && a2disconf serve-cgi-bin \
    && a2enconf charset \
    && a2enconf server-status \
    && a2enconf php-fpm \
    && a2enconf remoteip \
    && a2enconf performance \
    && a2enconf security

# remove unused logs
RUN rm -f /var/log/apache2/access.log
RUN rm -f /var/log/apache2/error.log
RUN rm -f /var/log/apache2/other_vhosts_access.log

#
# PHP
#
COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/conf.d/* /usr/local/etc/php/conf.d/

# install spx
WORKDIR /usr/lib
ADD https://github.com/NoiseByNorthwest/php-spx/archive/refs/heads/master.zip php-spx-master.zip
RUN unzip php-spx-master.zip && rm -f php-spx-master.zip
RUN mv php-spx-master php-spx
RUN cd /usr/lib/php-spx && phpize && ./configure && make && make install

#
# PHP-FPM
#
RUN mkdir -p /var/log/php-fpm
RUN rm -f /usr/local/etc/php-fpm.d/*
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm/php-fpm.conf /usr/local/etc/php-fpm.conf

#
# Apache exporter
#
WORKDIR /root
ADD https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.9/apache_exporter-1.0.9.linux-amd64.tar.gz apache_exporter-1.0.9.linux-amd64.tar.gz
RUN tar xfvz apache_exporter-1.0.9.linux-amd64.tar.gz
RUN mv apache_exporter-1.0.9.linux-amd64/apache_exporter /usr/bin/

#
# php-fpm exporter
#
ADD https://github.com/hipages/php-fpm_exporter/releases/download/v2.2.0/php-fpm_exporter_2.2.0_linux_amd64.tar.gz php-fpm_exporter_2.2.0_linux_amd64.tar.gz
RUN tar xfvz php-fpm_exporter_2.2.0_linux_amd64.tar.gz
RUN mv php-fpm_exporter /usr/bin/
COPY --chmod=755 ./php-fpm/php-fpm_exporter.sh /root/php-fpm_exporter.sh

#
# wwww dir
#
WORKDIR /var/www/

# secret-home
RUN rm -rf html/* secret-home/*
RUN mkdir -p ./secret-home/
COPY secret-home/* ./secret-home/
RUN chown www-data:www-data ./secret-home/

#
# MSMTP
#
COPY ./msmtp/msmtprc /usr/local/etc/msmtprc

#
# Supervisor
#
COPY ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY ./supervisor/apache-and-php.conf /etc/supervisor/conf.d/apache-and-php.conf

#
# Cron via supercronic
#

# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

RUN mkdir -p /etc/cron.minutely
RUN mkdir -p /etc/cron.5minutes
RUN mkdir -p /etc/cron.10minutes
RUN mkdir -p /etc/cron.15minutes
RUN mkdir -p /etc/cron.hourly
RUN mkdir -p /etc/cron.daily
RUN mkdir -p /etc/cron.weekly
RUN mkdir -p /etc/cron.monthly

COPY cron/crontab /etc/crontab

#
# Environment variables (runtime)
#
ENV PHP_FPM_MAX_CHILDREN=100
ENV PHP_FPM_START_SERVERS=10
ENV PHP_FPM_MIN_SPARE_SERVERS=5
ENV PHP_FPM_MAX_SPARE_SERVERS=10

ENV PHP_OPCACHE_MEMORY_CONSUMPTION=512

ENV PHP_APC_SHM_SIZE=1024M

ENV PHP_SPX_HTTP_KEY=abc123

ENV PHP_XDEBUG_ENABLE=0
ENV PHP_XDEBUG_TRIGGER=XDEBUG_TRIGGER

ENV APACHE_SECRET_HOME=/secret
ENV SECRET_HOME_USER=user
ENV SECRET_HOME_PASS=pass

ENV APACHE_DISABLE_COMPRESSION=1

ENV APACHE_LOG_NAME=www

ENV MSMTP_HOST=localhost
ENV MSMTP_FROM=default@example.com

ENV REDIS_HOST=127.0.0.1:6379

# Port we'll be running on (apache)
EXPOSE 80

#
# Run supervisor
#
COPY --chmod=755 ./docker-entrypoint.sh /root/docker-entrypoint.sh
CMD ["/root/docker-entrypoint.sh"]
