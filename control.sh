#!/bin/bash
. $(dirname "$(realpath "$0")")/.settings

s() {
    s=$1
    case "$1" in
        apache2)
            if ! which apache2 >/dev/null; then
                return;
            fi
            ;;
        php${PHP_VERSION}-fpm)
            if ! which php-fpm${PHP_VERSION} >/dev/null; then
                return;
            fi
            ;;
        mysql)
            if ! which mysqld >/dev/null; then
                return;
            fi
            ;;
        redis-server)
            if ! which redis-server >/dev/null; then
                return;
            fi
            ;;
        mongod)
            if ! which mongod >/dev/null; then
                return;
            fi
            if -e /etc/init.d/mongod; then
                s=mongod
            fi
            ;;
    esac
    service $s $2
}
all() {
    s apache2 $1
    s php${PHP_VERSION}-fpm $1
    s mysql $1
    s redis-server $1
    s mongodb $1
}
fix_run() {
    mkdir -p /run/php/
    mkdir -p /var/run/screen/
    chmod a+w /var/run/screen/
}
start() {
    all start
}
status() {
    all status
}
stop() {
    all stop
}
restart() {
    all restart
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
    Usage: '$0' <command>

    Commands:
        start       Starts all installed LAMP-services
        status      Shows status of all installed LAMP-services
        stop        Stops all installed LAMP-services
        restart     Restarts all installed LAMP-services
    '
}

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

fix_run
case "$1" in
    start)
        start
    ;;
    status)
        status
    ;;
    stop)
        stop
    ;;
    restart)
        restart
    ;;
    help|-h)
        usage
    ;;
    *)
        usage
    ;;
esac

