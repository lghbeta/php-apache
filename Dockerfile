FROM php:7.3-apache
MAINTAINER LGH <lghbeta@gmail.com>

ENV LD_LIBRARY_PATH=/usr/lib/instantclient_12_2
ENV ORACLE_HOME=/usr/lib/instantclient_12_2
ENV TNS_ADMIN=$ORACLE_HOME/network/admin

# install composer
RUN ln -s /usr/local/lib/php/ /php \
    && curl -sS https://getcomposer.org/installer | php \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer

# persistent dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 libbz2-dev \
        libwebp-dev libjpeg-dev libpng-dev libfreetype6-dev \
        zlib1g-dev libzip-dev \
        libicu-dev \
        libpq-dev \
        libaio1 \
        gnupg2 \
        locales \
    && RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSL https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        unixodbc-dev \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && curl -o instantclient.tar.gz -sSL https://github.com/lghbeta/php-apache/releases/download/instantclient/instantclient_12_2.tar.gz \
    && tar -zxvf instantclient.tar.gz -C /usr/lib/ \
    && ln -sf /usr/lib/instantclient_12_2/libclntsh.so.12.1 /usr/lib/instantclient_12_2/libclntsh.so \
    && rm -f instantclient.tar.gz \
    && rm -f /etc/apt/sources.list.d/mssql-release.list \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# install general extensions
RUN docker-php-ext-configure gd --with-webp-dir=/usr/include/webp --with-jpeg-dir=/usr/include --with-png-dir=/usr/include --with-freetype-dir=/usr/include/freetype2 \
    && docker-php-ext-install -j "$(nproc)" \
        bcmath \
        bz2 \
        exif \
        gettext \
        gd \
        intl \
        opcache \
        zip \
# install database extensions
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install -j "$(nproc)" \
        oci8 \
        pdo_oci \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && chown -R www-data:www-data /var/www

COPY index.php /var/www/html/
VOLUME /var/www/html
