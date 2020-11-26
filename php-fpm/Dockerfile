FROM php:7.4.0-fpm-buster

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libicu-dev libxml2-dev libzip-dev \
    libxpm-dev libcurl4-openssl-dev libxslt-dev libwebp-dev unzip git cron procps

RUN docker-php-ext-configure gd --with-webp --with-jpeg --with-xpm --with-freetype

RUN docker-php-ext-install -j5 bcmath gd intl \
    pdo_mysql sockets soap xsl zip

COPY php.ini $PHP_INI_DIR/

COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_HOME /root/composer_home

RUN mkdir /root/composer_home

COPY auth.json ${COMPOSER_HOME}

RUN composer --ansi global require hirak/prestissimo

WORKDIR /var/www/magento2
