#!/bin/bash

version=$MEMCACHED_VERSION

sudo apt-get -y remove memcached
sudo apt-get install libevent-dev

echo Start install Memcached ${version}

curl -LO http://www.memcached.org/files/memcached-${version}.tar.gz
tar xfz memcached-${version}.tar.gz
cd memcached-${version}
./configure --enable-64bit
make
sudo mv memcached /usr/local/bin/

echo Finish install Memcached ${version}
