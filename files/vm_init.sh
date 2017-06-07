#!/bin/bash

################################
INSTDIR=/tmp/install

JVER=jre1.8.0_131
JPATH=/opt/java
JURL=http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jre-8u131-linux-x64.tar.gz

CONFNAME=atlassian-confluence-6.1.4
CONFDIR=/usr/local/confluence/
CONFURL=https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-6.1.4.tar.gz

CONURL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.42.tar.gz
CONVER=5.1.42
################################

mkdir -p $INSTDIR

echo "Installing Nginx and Docker..." \
&& apt-get update \
&& apt-get -y install nginx #docker mysql-common mysql-server-5.5

echo "Setting up nginx..." \
&& rm -f /etc/nginx/sites-enabled/* \
&& cp $INSTDIR/nginx_site.conf /etc/nginx/sites-available/ \
&& ln -s /etc/nginx/sites-available/nginx_site.conf /etc/nginx/sites-enabled/ \
&& echo "Moving cert..." \
&& mkdir -p /etc/nginx/ssl \
&& mv $INSTDIR/test.crt /etc/nginx/ssl/test.crt \
&& mv $INSTDIR/test.key /etc/nginx/ssl/test.key \
&& echo "Creating nginx log-files"
&& mkdir -p /var/www/logs/ \
&& touch /var/www/logs/nginx_ssl_access.log \
&& touch /var/www/logs/nginx_ssl_error.log \
&& touch /var/www/logs/nginx_access.log \
&& touch /var/www/logs/nginx_error.log \
&& echo "Starting Nginx..." \
&& systemctl start nginx

[ ! -f "$INSTDIR/java.tar.gz" ] && echo "Downloading Java..." && wget --tries=2 --timeout=10 --quiet -O $INSTDIR/java.tar.gz --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" $JURL || echo "File exists, using cache" \
&& echo "Installing java..." \
&& mkdir -p $JPATH \
&& tar -zxf $INSTDIR/java.tar.gz -C $JPATH \
&& echo "Setting up java..." \
&& [ -z "$JAVA_HOME" ] && echo "export JAVA_HOME=$JPATH/$JVER" >> /etc/profile && source /etc/profile || echo "JAVA_HOME set to $JAVA_HOME" \
&& update-alternatives --install /usr/bin/java java $JPATH/$JVER/bin/java 100 \
#&& update-alternatives --config java \
#&& update-java-alternatives -s $JVER

[ ! -f "$INSTDIR/confluence.tar.gz" ] && echo "Docwnloading Confluence..." && wget --tries=2 --timeout=10 --quiet -O $INSTDIR/confluence.tar.gz $CONFURL || echo "File exists, using cache" \
&& echo "Adding users..." \
&& useradd --create-home -c "Confluence role account" confluence \
&& echo "Creating directories..." \
&& mkdir -p $CONFDIR \
&& chown confluence: $CONFDIR \
&& echo "Installing Confluence..." \
&& su -c "tar -zxf $INSTDIR/confluence.tar.gz -C $CONFDIR" confluence \
&& echo "Installing MySQL connector" \
&& [ ! -f "$INSTDIR/mysql-connector-java.tar.gz" ] && echo "Docwnloading connector..." && wget --tries=2 --timeout=10 --quiet -O $INSTDIR/mysql-connector-java.tar.gz $CONURL || echo "File exists, using cache" \
&& tar -xzf -C $INSTDIR $INSTDIR/installers/mysql-connector-java.tar.gz \
&& mv mysql-connector-java-$CONVER/mysql-connector-java-$CONVER-bin.jar /usr/local/confluence/$CONFNAME/confluence/lib/ \
&& echo "Configuring Confluence..." \
&& chown confluence: $CONFDIR/$CONFNAME \
&& mv $INSTDIR/confluence-init.properties /usr/local/confluence/$CONFNAME/confluence/WEB-INF/classes \
&& mv $INSTDIR/confluence.service /etc/systemd/system/ \
&& echo "Starting confluence..." \
&& systemctl enable confluence.service \
&& systemctl start confluence.service

echo "DONE"
