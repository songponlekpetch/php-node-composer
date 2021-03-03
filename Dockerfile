ARG PHP_VERSION=7.3
ARG COMPOSER_VERSION=1.10.20
ARG NODE_VERSION=8.9.4
ARG USER=docker
ARG UID=1000

FROM composer:${COMPOSER_VERSION} AS composer

FROM node:${NODE_VERSION}-slim AS node_base

FROM php:${PHP_VERSION}-fpm
ARG USER
ARG UID

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libc-client-dev \
    libkrb5-dev \
    zip \
    unzip

# PDF
RUN apt-get install -y --allow-unauthenticated \
    libgtk2.0-0 \
    libgdk-pixbuf2.0-0 \
    libfontconfig1 \
    libxrender1 \
    libx11-6 \
    libglib2.0-0 \
    libxft2 \
    libfreetype6 \
    libc6 \
    zlib1g \
    libstdc++6 \
    libgcc1

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure imap \
        --with-imap \
        --with-kerberos \
        --with-imap-ssl \
    && docker-php-ext-install pdo_mysql exif bcmath gd zip imap
COPY  ./php.ini "$PHP_INI_DIR/php.ini"

# Get Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install NodeJS from node_base
COPY --from=node_base /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node_base /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
RUN npm install -g yarn

# Create system user to run Composer and Artisan Commands and Node command
RUN useradd -G www-data,root -u $UID -d /home/$USER $USER
RUN mkdir -p /home/$USER/.composer && \
    chown -R $USER:$USER /home/$USER

# Set working directory
WORKDIR /var/www

USER $USER
