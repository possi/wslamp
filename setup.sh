#!/bin/bash
. $(dirname "$0")/.settings
DIR="$(dirname "$0")"
ADIR="$(realpath "$DIR")"

install() {
    if ! dpkg-query -l python-software-properties >/dev/null; then
        apt-get update || exit 1

        apt-get install -y \
            python-software-properties \
            software-properties-common
    fi
    
    if ! dpkg-query -l nodejs >/dev/null; then
        curl -sL https://deb.nodesource.com/setup_16.x | bash -
    fi
    if ! dpkg-query -l mariadb-server >/dev/null; then
        curl -sL "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF1656F24C74CD1D8" | apt-key add
        add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror2.hs-esslingen.de/mariadb/repo/10.2/ubuntu bionic main'
    fi
    #if ! dpkg-query -l mongodb-server >/dev/null; then
    #    curl -sL "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0C49F3730359A14518585931BC711F9BA15703C6" | apt-key add
    #    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    #fi

    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

    apt-get update || exit 1

    apt-get install -y\
        apache2 \
        libapache2-mod-php${PHP_VERSION} \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php-apcu \
        php-mongodb \
        php-redis \
        php-xdebug

    apt-get install -y
        php${PHP_VERSION}-json \
        || true

        # php${PHP_VERSION}-bcmath \
        # php${PHP_VERSION}-bz2 \
        # php${PHP_VERSION}-imap \
        # php${PHP_VERSION}-sqlite3 \
    
    apt-get install -y\
        php${PHP_VERSION}-json \
        || true
    
    apt-get install -y\
        nodejs

    apt-get install -y\
        redis-server \
        redis-tools

    apt-get install -y\
        mariadb-server \
        mariadb-client
}

install_utils() {
    apt-get install -y\
        yarn
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
}

copy_defaults() {
    cp -riv "$DIR/default_configs/etc/init.d/." /etc/init.d/ || exit 1
    cp -riv "$DIR/default_configs/etc/apache2/." /etc/apache2/ || exit 1
    cp -riv "$DIR/default_configs/etc/php/." /etc/php/${PHP_VERSION}/ || exit 1
    cp -riv "$DIR/default_configs/etc/sudoers.d/." /etc/sudoers.d/ || exit 1
}
symlink_helpers() {
    ln -sf "$ADIR/control.sh" /usr/local/sbin/lamp-control
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
    a2enmod proxy_fcgi proxy_http proxy_http2 proxy_wstunnel

    a2enmod vhost_alias rewrite ssl setenvif
    a2dissite 000-default
    a2ensite 050-localhost.conf
    a2ensite 100-wildcard-dev.conf
    a2ensite 200-ssl-wildcard-dev.conf
    a2ensite 110-wildcard-test.conf
    a2ensite 210-ssl-wildcard-test.conf

    select_php_version
}
run_install_fixes() {
    mkdir -p /run/php/
}
run_defaults_fixes() {
    sudo mysql -e 'UPDATE mysql.user SET plugin = "" WHERE Host = "localhost" AND User = "root" AND Password = ""'
    sudo mysql -e 'FLUSH PRIVILEGES'
}
select_php_version() {
    ALL_PHP_VERISIONS=(5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2)
    for DISABLE_PHP_VERSION in ${ALL_PHP_VERISIONS[*]}
    do
        a2dismod php${DISABLE_PHP_VERSION} >/dev/null 2>&1
        a2disconf php${DISABLE_PHP_VERSION}-fpm >/dev/null 2>&1
        service php${DISABLE_PHP_VERSION}-fpm stop >/dev/null 2>&1
    done
    a2enconf php${PHP_VERSION}-fpm || exit 1

    phpenmod -v ${PHP_VERSION} lamp-dev

    update-alternatives --set php /usr/bin/php${PHP_VERSION}

    test -f $DIR/.settings.local && sed -i 's/PHP_VERSION=".*"/PHP_VERSION="'$PHP_VERSION'"/' $DIR/.settings.local
    grep PHP_VERSION $DIR/.settings.local >/dev/null || echo 'PHP_VERSION="'$PHP_VERSION'"' >> $DIR/.settings.local
}
restart_php() {
    if service apache2 status; then
        service php${PHP_VERSION}-fpm restart
        service apache2 restart
    fi
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
        php-version     Switch to configured PHP-Version (via ENV $PHP_VERSION)
        cleanup         Uninstal outdated PHP-Versions
    '
}

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

case "$1" in
    install)
        install
        install_utils
        run_install_fixes
    ;;
    copy-files)
        copy_defaults
        symlink_helpers
    ;;
    set-defaults)
        configure_defaults
        run_defaults_fixes
    ;;
    php-version)
        if [ ! -z "$2" ]; then PHP_VERSION="$2"; fi;
        select_php_version
        restart_php
    ;;
    cleanup)
        apt remove "php7.0*" "php7.1*" "php7.2*" "php7.3*" "php5.6*"
    ;;
    help|-h)
        usage
    ;;
    *)
        usage
    ;;
esac
