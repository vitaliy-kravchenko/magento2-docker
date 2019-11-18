FROM php:7.2-fpm-buster

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev libicu-dev libxml2-dev \
    libxpm-dev libxslt-dev libwebp-dev unzip git

RUN docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
    --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
    --enable-gd-native-ttf

RUN docker-php-ext-install -j5 bcmath gd iconv intl json mbstring \
    pdo_mysql opcache pdo soap xml xsl zip

ENV COMPOSER_HOME /root/composer_home

RUN mkdir /root/composer_home

COPY auth.json ${COMPOSER_HOME}

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN composer --ansi global require hirak/prestissimo

WORKDIR /var/www/magento2
