# docker-apache-php-fpm

Container for Apache 2.4 + PHP-FPM 7/8.

Available at [hub.docker.com/r/nicjansma/apache-php-fpm](https://hub.docker.com/r/nicjansma/apache-php-fpm).

## Packages

* [PHP](https://www.php.net/) 7.2, 7.3, 7.4, 8.1 and 8.2
  * Built on top of the `php:${PHP_VERSION}-fpm` packages
* [Apache](https://httpd.apache.org/) 2.4.x
* [Xdebug](https://xdebug.org/) 3.4.x for debugging, tracing and profiling
* [SPX](https://github.com/NoiseByNorthwest/php-spx) 0.4.x for profiling
* [Supervisord](https://supervisord.org/) to keep things running
* [Supercronic](https://github.com/aptible/supercronic) for cron jobs
* [msmtp](https://wiki.debian.org/msmtp) for mail
* Developer tools such as `curl` `ping` `nano` `rsync` `telnet` `unzip` `wget` and more

## Features

* Apache in Event MPM mode with PHP-FPM for fast dynamic web content
* Great for running multiple websites behind a proxy / load balancer (e.g. behind [Traefik](https://traefik.io/traefik/))
* Per-container named log files for `apache2/`, `php-fpm/` and `supercronic/`
* [Xdebug](https://xdebug.org/) and [SPX](https://github.com/NoiseByNorthwest/php-spx) for PHP debugging and profiling
* A "secret" path that exposes Apache `/server-status`, PHP-FPM `/status`, Zend OpCache info, Zend OpCache flushing controls, an APCu browser, and more behind HTTP Basic Authentication
* Prometheus exporters for Apache, PHP APCu/OpCache and PHP-FPM
* Per-container crontab and/or directories to map cron files into

### Apache

Apache 2.4.x is installed with the following modules enabled:

```
core_module (static)
so_module (static)
watchdog_module (static)
http_module (static)
log_config_module (static)
logio_module (static)
version_module (static)
unixd_module (static)
access_compat_module (shared)
actions_module (shared)
alias_module (shared)
allowmethods_module (shared)
auth_basic_module (shared)
authn_core_module (shared)
authn_file_module (shared)
authz_core_module (shared)
authz_host_module (shared)
authz_user_module (shared)
autoindex_module (shared)
cgid_module (shared)
data_module (shared)
dir_module (shared)
env_module (shared)
expires_module (shared)
filter_module (shared)
headers_module (shared)
http2_module (shared)
include_module (shared)
info_module (shared)
macro_module (shared)
mime_module (shared)
mime_magic_module (shared)
mpm_event_module (shared)
negotiation_module (shared)
proxy_module (shared)
proxy_connect_module (shared)
proxy_fcgi_module (shared)
proxy_http_module (shared)
proxy_http2_module (shared)
remoteip_module (shared)
reqtimeout_module (shared)
rewrite_module (shared)
setenvif_module (shared)
status_module (shared)
 ```

A few default configuration directives are disabled:

```
&& a2disconf localized-error-pages \
&& a2disconf other-vhosts-access-log \
&& a2disconf serve-cgi-bin \
```

And a few optional configuration directives are enabled (see `apache/conf-available`):

```
&& a2enconf charset \
&& a2enconf server-status \
&& a2enconf php-fpm \
&& a2enconf remoteip \
&& a2enconf performance \
&& a2enconf security
```

#### Apache HTTPS / SSL / TLS

There is **no** HTTPS support enabled for Apache.

It is expected this container will live behind a proxy such as [Traefik](https://traefik.io/traefik/) that will handle TLS termination.  Traefik will communicate through these localhost containers over HTTP.

#### Apache Compression

By default, HTTP compression within Apache is disabled by the environment variable `APACHE_DISABLE_COMPRESSION=1`.

This means **no** compression (e.g. gzip, brotli or zstd) will be used in Apache HTTP responses.

It is expected this container will live behind a proxy such as [Traefik](https://traefik.io/traefik/) that will handle compression (better than Apache).

If you want to enable HTTP compression, you can set`APACHE_DISABLE_COMPRESSION=1`.

#### Apache Logging

Apache logs will go to `/var/log/apache2/` in the container.  This container path can be mapped to a local path if desired.

Logs will contain the `APACHE_LOG_NAME` environment variable in them, so multiple containers can log to the same directory.

The file names will be:

* `/var/log/apache2/access_[APACHE_LOG_NAME]_log`: Apache access log
* `/var/log/apache2/apache2.stderr.[APACHE_LOG_NAME].log`: Apache stderr
* `/var/log/apache2/apache2.stdout.[APACHE_LOG_NAME].log`: Apache stdout
* `/var/log/apache2/error_[APACHE_LOG_NAME]_log`: Apache error log

#### Apache `/server-status`

Apache server status is available through the _secret home_ (see below).

### PHP and PHP-FPM

There are multiple versions of this container for each PHP version:

`nicjansma/apache-php-fpm:[php-version]`

The following PHP versions are supported and tested:

* 7.2 `nicjansma/apache-php-fpm:7.2`
* 7.3 `nicjansma/apache-php-fpm:7.3`
* 7.4 `nicjansma/apache-php-fpm:7.4`
* 8.1 `nicjansma/apache-php-fpm:8.1`
* 8.2 `nicjansma/apache-php-fpm:8.2`

#### PHP Configuration

The following runtime environment variables can be set to control the PHP-FPM `www` pool settings:

* `PHP_FPM_MAX_CHILDREN=100`
* `PHP_FPM_START_SERVERS=10`
* `PHP_FPM_MIN_SPARE_SERVERS=5`
* `PHP_FPM_MAX_SPARE_SERVERS=10`

Zend OpCache is enabled by default.  You can configure the amount of memory (in MB) for it via:

* `PHP_OPCACHE_MEMORY_CONSUMPTION=512`

APCu is enabled by default.  You can configure the amount of memory for it via:

* `PHP_APC_SHM_SIZE=1024M`

This container expects a Redis host for PHP session management:

* `REDIS_HOST=127.0.0.1:6379`

#### PHP Extensions

The following PHP extensions are included:

* apcu
* bcmath
* brotli
* bz2
* calendar
* curl
* dba
* exif
* gd
* gettext
* gmp
* imagick
* intl
* json
* ldap
* luasandbox
* mbstring
* mongodb
* mysqli
* opcache
* pdo_mysql
* redis
* shmop
* snmp
* soap
* sockets
* ssh2
* vips
* xdebug
* xml
* xmlrpc
* xsl
* zip
* zstd

If you would like additional extensions, you can rebuild this container and change the `PHP_EXT_DEPS` build variable.

Alternatively, you can use something like [`install-php-extensions`](https://github.com/mlocati/docker-php-extension-installer) in a container composed on top of this one.

#### PHP Logging

PHP-FPM logs will go to `/var/log/php-fpm/` in the container.  This container path can be mapped to a local path if desired.

Logs will contain the `APACHE_LOG_NAME` environment variable in them, so multiple containers can log to the same directory.

The file names will be:

* `/var/log/php-fpm/php-fpm.error.[APACHE_LOG_NAME].log`: PHP-FPM error log
* `/var/log/php-fpm/php-fpm.php_error_log.[APACHE_LOG_NAME].log`: PHP-FPM PHP's `error_log` output
* `/var/log/php-fpm/php-fpm.stderr.[APACHE_LOG_NAME].log`: PHP-FPM stderr
* `/var/log/php-fpm/php-fpm.stdout.[APACHE_LOG_NAME].log`: PHP-FPM stdout
* `/var/log/php-fpm/php-fpm.www.[APACHE_LOG_NAME].access.log`: PHP-FPM access log

### Logging

This container's primary logs (for Apache, PHP-FPM and supercronic) are in the following directories:

* `/var/log/apache2/` for Apache
* `/var/log/php-fpm/` for PHP-FPM
* `/var/log/supercronic/` for Supercronic

Setting the runtime environment variable `{APACHE_LOG_NAME}` to something unique will allow you to map those directories to a path on the host (if desired), allowing multiple containers to all log to the same location (if desired) with a unique file name.  This can be useful for log processing and rotation.

### Xdebug

Xdebug is available inside the container, but is not enabled by default (to avoid runtime performance penalties).

To enable on a container-by-container basis, you can set `PHP_XDEBUG_ENABLE=1`.

If you'd like to be able to [step-debug](https://xdebug.org/docs/step_debug) PHP, you can set the `PHP_XDEBUG_TRIGGER=XDEBUG_TRIGGER` variable to `MyTrigger` (or something) -- a unique value you choose.

Then you would load a URL with `?XDEBUG_TRIGGER=MyTrigger` to enable step debugging for that request.

### SPX

SPX can be enabled at runtime with `PHP_SPX_HTTP_KEY=abc123`. You should change the value of `abc123` to a secret string.

Activating SPX can be done by visiting a URL with `?SPX_KEY=abc123&SPX_UI_URI=/`:

https://mydomain.com/?SPX_KEY=abc123&SPX_UI_URI=/

Once there, select _Enabled_ and future page navigations should be profiled.

### Secret Home

There is a virtual directory on the server, controlled by the runtime environment variable `APACHE_SECRET_HOME=/secret`.

This URL contains useful scripts and tools to peak inside the runtime configuration and status of the container.

To change the location of this directory, you can change the value of `APACHE_SECRET_HOME`.

It is protected by HTTP Basic Auth.  The username and password can be changed:

* `SECRET_HOME_USER=user`
* `SECRET_HOME_PASS=pass`

Inside of this path are several bundled scripts:

* [Apache server status](https://httpd.apache.org/docs/2.4/mod/mod_status.html) `/server-status`
* [Apache Prometheus Exporter](https://github.com/Lusitaniae/apache_exporter/)
* [APC information](https://github.com/krakjoe/apcu/blob/master/apc.php)
* `phpinfo()`
* PHP APCU and OpCache Prometheus Exporter (custom for this container)
* PHP-FPM `/status`
* [PHP-FPM Prometheus Exporter](https://github.com/hipages/php-fpm_exporter)
* [Zend OpCache information](https://github.com/carlosbuenosvinos/opcache-dashboard/)
* [Zend OpCache information #2](https://github.com/rlerdorf/opcache-status)
* Zend OpCache flush script

It also includes a rudimentary [live log viewer](https://github.com/ThomasDepole/Easy-PHP-Tail-) for:

* Apache access log
* Apache error log
* PHP error_log
* PHP-FPM errors
* PHP-FPM www log
* PHP-FPM www-slow log

### Prometheus Exporters

There are Prometheus exporters for:

* [Apache Prometheus Exporter](https://github.com/Lusitaniae/apache_exporter/)
* PHP APCU and OpCache Prometheus Exporter
* [PHP-FPM Prometheus Exporter](https://github.com/hipages/php-fpm_exporter)

These are protected by the _Secret Home_ HTTP Basic Authentication.

An example Prometheus rule could be:

```yaml
  - job_name: "apache-mywebsite"
    scheme: https
    metrics_path: "/secret/metrics/apache"
    basic_auth:
      username: "user"
      password: "pass"
    static_configs:
      - targets: ["mywebsite.com"]
        labels:
          job: "apache"
          instance: "mywebsite.com"
          app: "mywebsite"

  - job_name: "php-fpm-mywebsite"
    scheme: https
    metrics_path: "/secret/metrics/php-fpm"
    basic_auth:
      username: "user"
      password: "pass"
    static_configs:
      - targets: ["mywebsite.com"]
        labels:
          job: "php-fpm"
          instance: "mywebsite.com"
          app: "mywebsite"

  - job_name: "php-mywebsite"
    scheme: https
    metrics_path: "/secret/metrics/php"
    basic_auth:
      username: "user"
      password: "pass"
    static_configs:
      - targets: ["mywebsite.com"]
        labels:
          job: "php"
          instance: "mywebsite.com"
          app: "mywebsite"
```

### Cron

[Supercronic](https://github.com/aptible/supercronic) is used for cron jobs.

You can either:

* Map cron scripts into these directories:
  * `/etc/cron.minutely`
  * `/etc/cron.5minutes`
  * `/etc/cron.10minutes`
  * `/etc/cron.15minutes`
  * `/etc/cron.hourly`
  * `/etc/cron.daily`
  * `/etc/cron.weekly`
  * `/etc/cron.monthly`
* Replace with your own crontab to `/etc/crontab`

Logs will go to `/var/log/supercronic/` in the container.  This container path can be mapped to a local path if desired.

Logs will contain the `APACHE_LOG_NAME` environment variable in them, so multiple containers can log to the same directory.

* `/var/log/supercronic/supercronic.[APACHE_LOG_NAME].log`

### Mail

PHP will use [msmtp](https://wiki.debian.org/msmtp) to send email (via `php.ini` `sendmail_path` directive).

To configure where to forward messages to, you should change these runtime environment variables:

* `MSMTP_HOST=localhost`
* `MSMTP_FROM=default@example.com`

## Configuration

This `Dockerfile` uses Build Variables (`ARG`s) for the build (if you want to rebuild it), and runtime (`ENV`) variables to control behavior at container runtime.

### Build Variables

The following `ARG`s are used during the build of the docker container:

* `PHP_VERSION` controls the PHP version for this build

* `RUNTIME_PACKAGE_DEPS` controls which packages are available at container runtime
  * Default: `apache2 bash curl iputils-ping less libcurl4 libssh2-1 mariadb-client msmtp-mta nano rsync ssh sudo supervisor telnet unzip wget zstd`

* `BUILD_PACKAGE_DEPS` controls which packages are required during the container build
  * Default: `libcurl4-openssl-dev libjpeg-dev libpng-dev libssh2-1-dev libxml2-dev`

* `PHP_EXT_DEPS` controls which PHP extensions are included
  * Default: `apcu bcmath brotli bz2 calendar curl dba exif gd gettext gmp imagick intl json ldap luasandbox mbstring mongodb mysqli opcache pdo_mysql redis shmop snmp soap sockets ssh2 vips xdebug xml xmlrpc xsl zip zstd`

### Environment / Runtime Variables

The following `ENV`s are interpreted at container runtime, and can be set for each container instance.

The `docker-entrypoint.sh` script will read these variables and place them into various `.ini` and `.conf` files before Apache, PHP-FPM, etc are started.

Default settings are shown below.

Apache settings:

* `APACHE_SECRET_HOME=/secret`
* `SECRET_HOME_USER=user`
* `SECRET_HOME_PASS=pass`

* `APACHE_DISABLE_COMPRESSION=1`

* `APACHE_LOG_NAME=www`

PHP settings:

* `PHP_FPM_MAX_CHILDREN=100`
* `PHP_FPM_START_SERVERS=10`
* `PHP_FPM_MIN_SPARE_SERVERS=5`
* `PHP_FPM_MAX_SPARE_SERVERS=10`

* `PHP_OPCACHE_MEMORY_CONSUMPTION=512`

* `PHP_APC_SHM_SIZE=1024M`

* `PHP_SPX_HTTP_KEY=abc123`

* `PHP_XDEBUG_ENABLE=0`
* `PHP_XDEBUG_TRIGGER=XDEBUG_TRIGGER`

Mail:

* `MSMTP_HOST=localhost`
* `MSMTP_FROM=default@example.com`

Redis:

* `REDIS_HOST=127.0.0.1:6379`

## Examples

### Docker Run

Example command to run this container mapped to port 8001 locally:

```sh
docker run \
    -it \
    --rm \
    -p 8001:80 \
    -e APACHE_SECRET_HOME=/secret \
    -e APACHE_LOG_NAME=mywebsite \
    -e SECRET_HOME_USER=user \
    -e SECRET_HOME_PASS=pass \
    -e PHP_FPM_MAX_CHILDREN=100 \
    -e PHP_FPM_START_SERVERS=5 \
    -e PHP_FPM_MIN_SPARE_SERVERS=5 \
    -e PHP_FPM_MAX_SPARE_SERVERS=10 \
    -e PHP_OPCACHE_MEMORY_CONSUMPTION=128 \
    -e PHP_APC_SHM_SIZE=100M \
    -e PHP_SPX_HTTP_KEY=abc123 \
    -e PHP_XDEBUG_ENABLE=1 \
    -e PHP_XDEBUG_TRIGGER=XDEBUG_TRIGGER \
    -e MSMTP_HOST=smtp-relay \
    -e MSMTP_FROM=me@me.com \
    -e REDIS_HOST=redis:6379 \
    --name apache-php-fpm \
    apache-php-fpm:8.1
```

### Docker Compose

This example incorporates [Traefik](https://traefik.io/traefik/) in a `docker-compose.yml`

```yml
services:

  traefik:
    container_name: traefik
    image: traefik:latest
    restart: always
    networks:
      proxy:
    security_opt:
      - no-new-privileges:true
    ports:
      - 0.0.0.0:80:80 # http
      - 0.0.0.0:443:443/tcp # https
      - 0.0.0.0:443:443/udp # https h/3
    volumes:
      # connect to docker socket for auto mode
      - /var/run/docker.sock:/var/run/docker.sock:ro

      # config files
      - /data/traefik/config/traefik.yml:/traefik.yml

  mywebsite:
    image: nicjansma/apache-php-fpm:8.1
    container_name: mywebsite
    restart: unless-stopped
    networks:
      proxy:
      backend:
    volumes:
      # HTML
      - /home/mywebsite/html/:/var/www/html/
      # logs
      - /data/logs/apache2/:/var/log/apache2/
      - /data/logs/php-fpm/:/var/log/php-fpm/
      - /data/logs/supercronic/:/var/log/supercronic/
    environment:
      - APACHE_SECRET_HOME=/secret
      - APACHE_LOG_NAME=mywebsite
      - SECRET_HOME_USER=user
      - SECRET_HOME_PASS=pass
      - PHP_FPM_MAX_CHILDREN=100
      - PHP_FPM_START_SERVERS=5
      - PHP_FPM_MIN_SPARE_SERVERS=5
      - PHP_FPM_MAX_SPARE_SERVERS=10
      - PHP_OPCACHE_MEMORY_CONSUMPTION=128
      - PHP_APC_SHM_SIZE=100M
      - PHP_SPX_HTTP_KEY=abc123
      - PHP_XDEBUG_ENABLE=1
      - PHP_XDEBUG_TRIGGER=XDEBUG_TRIGGER
      - MSMTP_HOST=smtp-relay
      - MSMTP_FROM=me@me.com
      - REDIS_HOST=redis:6379
    labels:
      - traefik.enable=true
      - traefik.port=80
      # http://www.mywebsite.com/ redirect
      - traefik.http.routers.mywebsite.entrypoints=web
      - traefik.http.routers.mywebsite.rule=Host(`mywebsite.com`) || Host(`www.mywebsite.com`)
      - traefik.http.routers.mywebsite.middlewares=https-redirect@file
      # https://www.mywebsite.com/
      - traefik.http.routers.mywebsite-secure.entrypoints=webSecure
      - traefik.http.routers.mywebsite-secure.rule=Host(`mywebsite.com`) || Host(`www.mywebsite.com`)
      - traefik.http.routers.mywebsite-secure.tls=true
      - traefik.http.routers.mywebsite-secure.tls.certresolver=letsencrypt
      - traefik.http.routers.mywebsite-secure.tls.domains[0].main=mywebsite.com
      - traefik.http.routers.mywebsite-secure.tls.domains[0].sans=www.mywebsite.com
      # service
      - traefik.http.services.mywebsite.loadbalancer.server.port=80

#
# networks
#
networks:
  proxy:
    external: true
  backend:
    external: true
```

## Version History

* v1.0.0 - 2025-06-11
  * Initial release
