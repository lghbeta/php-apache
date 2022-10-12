FROM php:7.3-apache
MAINTAINER LGH <lghbeta@gmail.com>

ENV LD_LIBRARY_PATH=/usr/lib/instantclient_12_2
ENV ORACLE_HOME=/usr/lib/instantclient_12_2
ENV TNS_ADMIN=$ORACLE_HOME/network/admin

# install composer
RUN ln -s /usr/local/lib/php/ /php \
    && ln -s /usr/local/etc/php/ /etc/php \
    && curl -sS https://getcomposer.org/installer | php \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer

# persistent dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 libbz2-dev \
        libjpeg-dev libwebp-dev libpng-dev libfreetype6-dev \
        zlib1g-dev libzip-dev \
        libicu-dev \
        libpq-dev \
        libaio1 \
        gnupg2 \
        locales \
# sqlsrv dependencies
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSL https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        unixodbc-dev \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
# oci dependencies
    && curl -o instantclient.tar.gz -sSL https://github.com/lghbeta/php-apache/releases/download/dependency/instantclient_12_2.tar.gz \
    && tar -zxvf instantclient.tar.gz -C /usr/lib/ \
    && ln -sf /usr/lib/instantclient_12_2/libclntsh.so.12.1 /usr/lib/instantclient_12_2/libclntsh.so \
# cn fonts
    && curl -o cnfonts.tar.gz -sSL https://github.com/lghbeta/php-apache/releases/download/dependency/cnfonts.tar.gz \
    && tar -zxvf cnfonts.tar.gz -C /usr/share/fonts/truetype/ \
    && fc-cache -fv \
# wkhtmltox dependencies
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
# cleanup
    && rm -f instantclient.tar.gz wkhtmltox.deb \
    && rm -f /etc/apt/sources.list.d/mssql-release.list \
    && rm -rf /var/lib/apt/lists/*

# install general extensions
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include --with-webp-dir=/usr/include/webp --with-png-dir=/usr/include --with-freetype-dir=/usr/include/freetype2 \
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
    && docker-php-ext-install mysqli \
        pdo_mysql \
        pgsql \
        pdo_pgsql \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install -j "$(nproc)" \
        oci8 \
        pdo_oci \
    && pecl install sqlsrv \
        pdo_sqlsrv \
    && docker-php-ext-enable \
        sqlsrv \
        pdo_sqlsrv

COPY index.php /var/www/html/
VOLUME /var/www/html
