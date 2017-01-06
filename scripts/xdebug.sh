#!/bin/bash

sudo apt-get -y install php5-xdebug

cd /etc/php5/mods-available || exit
echo "xdebug.remote_autostart=1" >> xdebug.ini
echo "xdebug.default_enable=0" >> xdebug.ini
echo "xdebug.remote_enable=0" >> xdebug.ini
echo "xdebug.remote_remote_enable=0" >> xdebug.ini
echo "xdebug.remote_host=localhost" >> xdebug.ini
echo "xdebug.remote_port=9000" >> xdebug.ini
echo "xdebug.idekey=xdebug" >> xdebug.ini
echo "xdebug.profiler_enable=0" >> xdebug.ini

sudo service apache2 restart


