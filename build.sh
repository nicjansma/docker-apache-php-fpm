#!/bin/sh

# Specific version
if [ ! -z "$1" ]; then
    PHP_VERSION=$1
    TAG_SUFFIX=$2

    sudo docker buildx build -t apache-php-fpm:$PHP_VERSION --platform linux/amd64 -f Dockerfile --build-arg PHP_VERSION=$PHP_VERSION .
    sudo docker tag apache-php-fpm:$PHP_VERSION nicjansma/apache-php-fpm:$PHP_VERSION$TAG_SUFFIX

    exit 1
fi

# All versions
sudo docker buildx build --platform linux/amd64 -t apache-php-fpm:7.2 -f Dockerfile --build-arg PHP_VERSION=7.2 .
sudo docker tag apache-php-fpm:7.2 nicjansma/apache-php-fpm:7.2

sudo docker buildx build --platform linux/amd64 -t apache-php-fpm:7.3 -f Dockerfile --build-arg PHP_VERSION=7.3 .
sudo docker tag apache-php-fpm:7.3 nicjansma/apache-php-fpm:7.3

sudo docker buildx build --platform linux/amd64 -t apache-php-fpm:7.4 -f Dockerfile --build-arg PHP_VERSION=7.4 .
sudo docker tag apache-php-fpm:7.4 nicjansma/apache-php-fpm:7.4

sudo docker buildx build --platform linux/amd64 -t apache-php-fpm:8.1 -f Dockerfile --build-arg PHP_VERSION=8.1 .
sudo docker tag apache-php-fpm:8.1 nicjansma/apache-php-fpm:8.1

sudo docker buildx build --platform linux/amd64 -t apache-php-fpm:8.2 -f Dockerfile --build-arg PHP_VERSION=8.2 .
sudo docker tag apache-php-fpm:8.2 nicjansma/apache-php-fpm:8.2
