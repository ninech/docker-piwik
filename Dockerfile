FROM php:5.6-fpm

MAINTAINER pierre@piwik.org

RUN apt-get update && apt-get install -y \
      libjpeg-dev \
      libfreetype6-dev \
      libgeoip-dev \
      libpng12-dev \
      libldap2-dev \
      zip \
 && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 	&& docker-php-ext-install -j$(nproc) gd mbstring mysql pdo_mysql zip ldap opcache

RUN pecl install APCu geoip

ENV PIWIK_VERSION 3.0.2
ENV PIWIK_HOME /var/www/html

COPY php.ini /usr/local/etc/php/php.ini

RUN curl -fsSL -o piwik.tar.gz \
      "https://builds.piwik.org/piwik-${PIWIK_VERSION}.tar.gz" \
 && curl -fsSL -o piwik.tar.gz.asc \
      "https://builds.piwik.org/piwik-${PIWIK_VERSION}.tar.gz.asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 814E346FA01A20DBB04B6807B5DBD5925590A237 \
 && gpg --batch --verify piwik.tar.gz.asc piwik.tar.gz \
 && rm -r "$GNUPGHOME" piwik.tar.gz.asc \
 && tar -xzf piwik.tar.gz -C "$PIWIK_HOME" --strip-components=1 \
 && rm piwik.tar.gz

RUN curl -fsSL -o "$PIWIK_HOME/misc/GeoIPCity.dat.gz" http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
 && gunzip "$PIWIK_HOME/misc/GeoIPCity.dat.gz"

RUN mkdir /config \
 && ln -s /config/config.ini.php "$PIWIK_HOME/config/config.ini.php"

COPY config.ini.php "/config/config.ini.php"

VOLUME "/var/www/html/tmp"
