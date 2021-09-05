FROM php:8-fpm-alpine AS base

WORKDIR /app
VOLUME /app

## Define default senvironment variables
ARG APP_ENV
ENV APP_ENV "${APP_ENV:-dev}"

## Configure default development configuration
RUN mv "${PHP_INI_DIR}/php.ini-development" "${PHP_INI_DIR}/php.ini"

## Override with custom configuration
COPY ./docker/php-fpm/config/* ${PHP_INI_DIR}/conf.d/
COPY ./docker/php-fpm/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

COPY . .

# https://github.com/phpdocker-io/phpdocker.io/blob/master/infrastructure/nginx/nginx.conf
