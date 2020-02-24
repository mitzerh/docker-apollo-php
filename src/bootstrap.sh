#!/bin/sh

# Bootstrap for installations
#
# Environment variables:
#
#   root        - (required) The level above document root folder in /usr/local/root (and /var/www/root symlink)
#               e.g. example.com
#
#   APP_NODE_VERSION - (optional) nodejs version to install
#   APP_NPM_VERSION  - (optional) npm version to install (optional)
#

# Log the bootstrap
LOG=/tmp/bootstrap.log

# setup apache config
if [ -d "/etc/httpd/conf" ]; then

    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.orig
    sed -i 's/#ServerName www\.example\.com:80/ServerName localhost:80/' /etc/httpd/conf/httpd.conf

fi

# User for apache; this is apache in RedHat distros and typically www-data in Debian distros.
# CentOS is derived from RedHat
if [ -z "${APACHE_USER}" ]
then
    APACHE_USER=apache
    echo `date +'%Y-%m-%d %T'`": APACHE_USER assigned as ${APACHE_USER}" >> $LOG
else
    echo `date +'%Y-%m-%d %T'`": Using APACHE_USER ${APACHE_USER}" >> $LOG
fi

# HOME directory for Apache
APACHE_HOME=/home/$APACHE_USER

# .ssh directory set up from users home - expected in docker-compose.yml
[ -d /root/.ssh ] || mkdir -m 0700 /root/.ssh
if [ -d /root/.ssh_xfer ]
then
    echo `date +'%Y-%m-%d %T'`: Copying /root/.ssh_xfer to /root/.ssh >> $LOG
    cp /root/.ssh_xfer/* /root/.ssh
    chmod 0600 /root/.ssh/*
else
    echo `date +'%Y-%m-%d %T'`: Warning: No /root/.ssh_xfer mounted to copy to /root/.ssh >> $LOG
fi

#echo `date +'%Y-%m-%d %T'`: Bootstrapping... >> $LOG

# Create /var/log/www-data
if [ ! -d "/var/log/www-data" ]
then
    mkdir -p /var/log/www-data
    chown $APACHE_USER:$APACHE_USER /var/log/www-data
fi

# This symlink maked the bootstrap visible too from `local.py wlog`
ln -s $LOG /var/log/www-data/bootstrap.log

# Always have the same stack identity
STACKIDENTITY=local

if [ -z "${root}" ]
then

    echo "Error: root evironment variable must be defined - e.g. example.com" >> $LOG

else

    # symlink
    if [ -d "/usr/local/root/${root}" ]; then

        if [ ! -d "/var/www/root" ]; then
            mkdir -p /var/www/root
        fi

        if [ ! -L "/var/www/root/${root}" ]; then
            ln -s /usr/local/root/${root}/ /var/www/root/${root}
        fi

    else
        echo "Error: /usr/local/root/${root} does not exist" >> $LOG
        exit 1;
    fi

    # Favour the local VirtualHosts file
    if [ -f ~/conf.d_xfer/vhosts.conf ]
    then
        cp ~/conf.d_xfer/vhosts.conf /etc/httpd/conf.d/vhosts.conf
    fi

    # Favour the local custom.conf
    if [ -f ~/conf.d_xfer/custom.conf ]
    then
        cp ~/conf.d_xfer/custom.conf /etc/httpd/conf.d/custom.conf
    fi

    # Verify syntax
    if [[ `apachectl -t 2>&1` =~ 'Syntax OK' ]]
    then

        cd /

        # HOME directory for Apache required for AWS Profiles
        export HOME="${APACHE_HOME}"

        echo `date +'%Y-%m-%d %T'`": exec-ing /usr/sbin/httpd -D FOREGROUND for PID 1" >> $LOG
        exec /usr/sbin/httpd -D FOREGROUND

        echo "Crashed!" >> $LOG
    else
        echo "Error: Bad syntax in /etc/httpd/conf.d/vhosts.conf" >> $LOG
        apachectl -t >> $LOG 2>&1
    fi

fi


# install specific node version
if [ ! -z "${APP_NODE_VERSION}" ]; then
    npm install -g n
    n ${NODE_VERSION} || echo "Error: invalid nodejs version: ${NODE_VERSION}" >> $LOG
fi

# install specific npm version
if [ ! -z "${APP_NPM_VERSION}" ]; then
    npm install -g npm@${NPM_VERSION} || echo "Error: invalid npm version: ${NPM_VERSION}" >> $LOG
fi

# Sleep (for diagnostics)
while true
do
    echo `date +'%Y-%m-%d %T'`": Sleeping because crashed" >> $LOG
    sleep 30
done

# End of file
