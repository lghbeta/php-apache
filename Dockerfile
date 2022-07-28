FROM php:7.3-apache
MAINTAINER LGH <lghbeta@gmail.com>

ENV LD_LIBRARY_PATH=/usr/lib/instantclient_12_2
ENV ORACLE_HOME=/usr/lib/instantclient_12_2
ENV TNS_ADMIN=$ORACLE_HOME/network/admin

# Install extensions: mysql/postgresql/oracle/sqlserver
RUN && ln -s /usr/local/lib/php/ /php \
    && curl -sS https://getcomposer.org/installer | php \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libwebp-dev libjpeg-dev libpng-dev libfreetype6-dev \ # for gd
        bzip2 libbz2-dev \                                    # for bz2
        zlib1g-dev libzip-dev \                               # for zip
        libpq-dev \                                           # for pgsql
        libaio1 \                                             # for oci
        gnupg2 \
        locales \
    && docker-php-ext-configure gd --with-webp-dir=/usr/include/webp --with-jpeg-dir=/usr/include --with-png-dir=/usr/include --with-freetype-dir=/usr/include/freetype2 \
    && docker-php-ext-install gd opcache bz2 zip gettext exif \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSL https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && curl -o instantclient.tar.gz -sSL https://github.com/lghbeta/php-apache/releases/download/instantclient/instantclient_12_2.tar.gz \
    && tar -zxvf instantclient.tar.gz -C /usr/lib/ \
    && rm -f instantclient.tar.gz \
    && ln -sf /usr/lib/instantclient_12_2/libclntsh.so.12.1 /usr/lib/instantclient_12_2/libclntsh.so \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get -y --no-install-recommends install unixodbc-dev msodbcsql17 \
    && rm -f /etc/apt/sources.list.d/mssql-release.list \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install pdo mysqli pdo_mysql pgsql pdo_pgsql \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install oci8 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install pdo_oci \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

COPY index.php /var/www/html/
