#!/bin/bash
PHP_VERSION="7.1"
DIR="$(dirname "$0")"
ADIR="$(realpath "$DIR")"

install() {
    apt-get update || exit 1

    apt-get install -y \
        python-software-properties \
        software-properties-common
    
    curl -sL https://deb.nodesource.com/setup_6.x | bash -
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

    apt-get update

    apt-get install -y\
        apache2 \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-mcrypt \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-gd \
        php-xdebug \
        php-apcu \
        nodejs
}

install_utils() {
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    npm install -g bower
}

copy_defaults() {
    cp -riv "$DIR/default_configs/etc/apache2/." /etc/apache2/ || exit 1
    cp -riv "$DIR/default_configs/etc/php/." /etc/php/${PHP_VERSION}/ || exit 1
}
symlink_helpers() {
    ln -sf "$ADIR/control.sh" /usr/local/bin/lamp-control
    for d in "/mnt/c/xampp/htdocs" "/mnt/d/xampp/htdocs" "/mnt/c/lamp/htdocs" "/mnt/d/lamp/htdocs" "$ADIR/htdocs";
    do
        if [ -d $d ]; then
            test -s /var/www/htdocs && rm -f /var/www/htdocs
            ln -s $d /var/www/htdocs
            break;
        fi
    done
}
configure_defaults() {
    a2enmod php${PHP_VERSION} || exit 1
    a2enmod vhost_alias
    a2enmod ssl
    a2dissite 000-default
    a2ensite 050-localhost.conf
    a2ensite 100-wildcard-dev.conf
    a2ensite 200-ssl-wildcard-dev.conf
    a2ensite 110-wildcard-test.conf
    a2ensite 210-ssl-wildcard-test.conf
    phpenmod lamp-dev
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
        copy-files      Install Apache-VirtualHost-Configurations and PHP Default-Settings and helper symlinks
        set-defaults    Enable Apache-Modules and -Sites
    '
}

case "$1" in
    install)
        install
        install_utils
    ;;
    copy-files)
        copy_defaults
        symlink_helpers
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
