#!/bin/bash

################################
INSTDIR=/tmp/install

JVER=jre1.8.0_131
JPATH=/opt/java
JURL=http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz

CONFNAME=atlassian-confluence-6.1.4
CONFDIR=/usr/local/confluence
CONFURL=https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-6.1.4.tar.gz
################################

mkdir -p $INSTDIR

echo "Installing Nginx and Docker..." \
&& apt-get update \
&& apt-get -y install nginx #docker

echo "Setting up nginx..." \
&& rm -f /etc/nginx/sites-enabled/* \
&& cp $INSTDIR/nginx_site.conf /etc/nginx/sites-available/ \
&& ln -s /etc/nginx/sites-available/nginx_site.conf /etc/nginx/sites-enabled/ \
&& mkdir -p /etc/nginx/ssl \
&& echo "moving cert..." \
&& mv $INSTDIR/test.key /etc/nginx/ssl/test.key \
&& mv $INSTDIR/test.csr /etc/nginx/ssl/test.csr \
&& mkdir -p /var/www/logs/ \
&& touch /var/www/logs/nginx_ssl_access.log \
&& touch /var/www/logs/nginx_ssl_error.log \
&& touch /var/www/logs/nginx_access.log \
&& touch /var/www/logs/nginx_error.log \
&& systemctl start nginx

echo "Downloading java..." \
&& wget --tries=2 --timeout=10 --quiet -O $INSTDIR/java.tar.gz --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" $JURL \
&& echo "Installing java..." \
&& mkdir -p $JPATH \
&& tar -zxf $INSTDIR/java.tar.gz -C $JPATH \
&& echo "Setting up java..." \
&& echo "export JAVA_HOME=$JPATH/$JVER" >> /etc/profile \
&& source /etc/profile \
&& update-alternatives --install /usr/bin/java java $JPATH/$JVER/bin/java 100 \
#&& update-alternatives --config java \
#&& update-java-alternatives -s $JVER

echo "Docwnloading confluence..." \
&& wget --tries=2 --timeout=10 --quiet -O $INSTDIR/confluence.tar.gz $CONFURL \
&& echo "Adding users..." \
&& useradd --create-home -c "Confluence role account" confluence \
&& echo "Creating directories..." \
&& mkdir -p $CONFDIR \
&& chown confluence: $CONFDIR \
&& echo "Installing confluence..." \
&& su -c "tar -zxf $INSTDIR/confluence.tar.gz -C $CONFDIR" confluence \
&& ln -s $CONFDIR/$CONFNAME $CONFDIR/current \
&& chown confluence: $CONFDIR/current \
&& echo "confluence.home=$CONFDIR/$CONFNAME" >> $CONFDIR/current/confluence/WEB-INF/classes/confluence-init.properties \
&& mv $INSTDIR/confluence.service /etc/systemd/system/ \
&& echo "Starting confluence..." \
&& systemctl start confluence

# echo "Starting docker container"

echo "DONE"