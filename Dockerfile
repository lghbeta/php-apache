FROM php:7.3-apache
MAINTAINER LGH <lghbeta@gmail.com>

ENV LD_LIBRARY_PATH=/usr/lib/instantclient_12_2
ENV ORACLE_HOME=/usr/lib/instantclient_12_2

# Common extensions
RUN ln -s /usr/local/lib/php/ /php \
    && docker-php-ext-install pdo mysqli pdo_mysql

# PostgreSQL Prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpq-dev \
    && docker-php-ext-install pgsql pdo_pgsql

# Oracle Prerequisites
RUN curl -o instantclient.tar.gz -sSL https://github.com/lghbeta/php-apache/releases/download/instantclient/instantclient_12_2.tar.gz \
    && tar -zxvf instantclient.tar.gz -C /usr/lib/ \
    && ln -sf /usr/lib/instantclient_12_2/libclntsh.so.12.1 /usr/lib/instantclient_12_2/libclntsh.so \
    && rm -f instantclient.tar.gz \
    && apt-get update \
    && apt-get install -y --no-install-recommends libaio1 \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install oci8 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/instantclient_12_2 \
    && docker-php-ext-install pdo_oci \
    && rm -rf /var/lib/apt/lists/*

# SQL Server Prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg2 locales \
    && curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSL https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get -y --no-install-recommends install unixodbc-dev msodbcsql17 \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && rm -f /etc/apt/sources.list.d/mssql-release.list \
    && rm -rf /var/lib/apt/lists/*

COPY index.php /var/www/html/
