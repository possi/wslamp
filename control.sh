#!/bin/bash

s() {
    case "$1" in
        apache2)
            if ! which apache2 >/dev/null; then
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
    esac
    service $1 $2
}
all() {
    s apache2 $1
    s mysql $1
    s redis-server $1
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

