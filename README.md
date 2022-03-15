## LAMP on Windows Subsystem for Linux (WSL)

This Tools help to setup my personal LAMP Default-Configuration on Windows 10 Ubuntu-18.04-Bash.

### /mnt Filesystem

For Permission see `example_config/wsl.conf` (to be placed as `/etc/wsl.conf`)

### Apache2 User-Permission

In `/etc/apache2/envvars` change:
```bash
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
```

And in `/etc/php/7.2/fpm/pool.d/www.conf` change:
```
user = www-data
group = www-data
```

to your current user/group (see `id`)


### MongoDB 3.4 (deprecated) Optional Install

```bash
    curl -sL "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0C49F3730359A14518585931BC711F9BA15703C6" | sudo apt-key add
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
```

### Select PHP Version

```bash
# First Time
sudo PHP_VERION=7.4 ./setup.sh install
sudo PHP_VERION=7.4 ./setup.sh copy-defaults

# Switch between already installed at any time
sudo ./setup.sh php-version 7.4
```
