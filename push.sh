#!/bin/bash

if [ ! -z "$1" ]; then
    PHP_VERSION=$1
    TAG_SUFFIX=$2

    sudo docker push nicjansma/apache-php-fpm:$PHP_VERSION$TAG_SUFFIX

    exit 1
fi

sudo docker push nicjansma/apache-php-fpm:7.2

sudo docker push nicjansma/apache-php-fpm:7.3

sudo docker push nicjansma/apache-php-fpm:7.4

sudo docker push nicjansma/apache-php-fpm:8.1

sudo docker push nicjansma/apache-php-fpm:8.2
