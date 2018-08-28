FROM ubuntu:16.04
LABEL mantainer="dhiraj.patra@gmail.com"


# Setup and install base system software
USER root
ENV DEBIAN_FRONTEND noninteractive

RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections \
    && echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections \
    && apt-get update \
    && apt-get update && apt-get install -y --no-install-recommends apt-utils \
    && apt-get --yes --no-install-recommends install \
        locales tzdata sudo \
        ca-certificates apt-transport-https software-properties-common \
        bash-completion iproute2 curl unzip nano tree \
    && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8


# Install supervisord
RUN apt-get update \
    && apt-get --yes --no-install-recommends install \
        supervisor dirmngr \
    && rm -rf /var/lib/apt/lists/*


# Install MySQL
ENV MYSQL_DEFAULT_PASSWORD uYqBu/41C4Iog4vq9eShKg==

RUN echo "mysql-server-5.7 mysql-server/root_password_again password ${MYSQL_DEFAULT_PASSWORD}" | debconf-set-selections \
    && echo "mysql-server-5.7 mysql-server/root_password password ${MYSQL_DEFAULT_PASSWORD}" | debconf-set-selections \
    && apt-get update && apt-get install --yes \
        mysql-server-5.7 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/mysql /var/run/mysqld /var/mysqld/ \
    && chown mysql:mysql /var/lib/mysql /var/run/mysqld /var/mysqld/


# Install NGINX and PHP
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        nginx \
        php7.0-fpm \
        php7.0-mbstring php7.0-xml php7.0-curl php7.0-zip php7.0-gd php7.0-mysql \
        composer \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/sites-enabled/default \
    && sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini \
    && mkdir /run/php


# Install Raha
ENV RAHA_VERSION 1.0

WORKDIR /tmp/
RUN mkdir -p /var/www/raha/root \
    && curl \
        --location \
        -o raha.zip \
        https://github.com/dhirajpatra/raha/archive/${RAHA_VERSION}.zip \
    && unzip raha.zip \
    && rm raha.zip \
    && find raha-*/ -mindepth 1 -maxdepth 1 -exec mv -t /var/www/raha/ -- {} + \
    && rmdir raha-* \
    && chown -R www-data:www-data /var/www/raha


# Install dependencies and config files
# NOTE: Change to www-data as composer should never run as root.
#       See https://getcomposer.org/root
USER www-data
WORKDIR /var/www/raha
RUN composer install \
    && php artisan vendor:publish --provider="Fideloper\Proxy\TrustedProxyServiceProvider" \
    && cp -R /var/www/raha/config /var/www/raha/config.package


# Install files
USER root
COPY supervisord/*.conf /etc/supervisor/conf.d/

COPY nginx/raha /etc/nginx/sites-available/raha
RUN chown www-data:www-data /etc/nginx/sites-available/raha \
    && ln -s /etc/nginx/sites-available/raha /etc/nginx/sites-enabled


# Start supervisord
EXPOSE 8080/TCP

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
