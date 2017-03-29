#!/bin/bash
PHP_VERSION="7.1"
DIR="$(dirname "$0")"

install() {
    apt-get update || exit 1

    apt-get install -y \
        python-software-properties \
        software-properties-common

    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php

    apt-get update

    apt-get install \
        apache2 \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php-xdebug
}
copy_defaults() {
    cp -riv "$DIR/default_configs/." / || exit 1
}
configure_defaults() {
    a2enmod php${PHP_VERSION} || exit 1
    a2enmod vhost_alias
    a2enmod ssl
    a2dissite 000-default
    a2ensite 050-localhost.conf
    a2ensite 100-wildcard-dev.conf
    a2ensite 200-ssl-wildcard-dev.conf
}

function hr {
  sed '
  1d
  $d
  s/  //
  ' <<< "$1"
}
function usage {
    hr '
    Usage: '$0' [command]
    
    Commands:
        install         Install Apache, PHP etc, via apt-get install
        copy-files      Install Apache-VirtualHost-Configurations and PHP Default-Settings
        set-defaults    Enable Apache-Modules and -Sites
    '
}

case "$1" in
    install)
        install
    ;;
    copy-files)
        copy_defaults
    ;;
    set-defaults)
        configure_defaults
    ;;
    help|-h)
        usage
    ;;
    *)
        usage
    ;;
esac
