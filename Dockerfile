FROM ubuntu:mpos

MAINTAINER nrpatten

RUN rm -rf /usr/sbin/policy-rc.d 
ADD policy-rc.d /usr/sbin/policy-rc.d
RUN chmod +x /usr/sbin/policy-rc.d

ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_PID_FILE  /var/run/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_USER_UID 0
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq && apt-get install -y apt-utils perl --no-install-recommends

RUN apt-get install -y --force-yes \
    build-essential \
    apache2 \
    libapache2-mod-php5 \
    pwgen \
    supervisor \
    curl \
    openssh-server \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libdb5.1-dev \
    libdb5.1++-dev \
    mysql-server \
    git \
    python-twisted \
    python-mysqldb \
    python-dev \
    python-setuptools \
    python-memcache \
    python-simplejson \
    python-pylibmc \
    memcached \
    php5-memcached \
    php5-mysqlnd \
    php5-curl \
    php5-json \
    libapache2-mod-php5

RUN easy_install -U distribute

RUN rm -rf /etc/apache2/apache2.conf
ADD apache2.conf /etc/apache2/apache2.conf
ADD apache_default /etc/apache2/sites-available/000-default.conf

RUN cd /var/www && git clone git://github.com/MPOS/php-mpos.git mpos

RUN cd /var/www/mpos && git checkout master && chown -R www-data templates/compile templates/cache logs

ADD global.inc.php /var/www/mpos/include/config/global.inc.php
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

RUN rm -rf /var/lib/mysql/*

ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

RUN a2enmod rewrite

RUN service apache2 restart

ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

RUN mkdir /var/run/sshd
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
ADD supervisord-openssh-server.conf /etc/supervisor/conf.d/supervisord-openssh-server.conf

EXPOSE 80 443 3306 22
CMD ["/run.sh"]