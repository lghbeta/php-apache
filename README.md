This image contains Debian's Apache httpd in conjunction with PHP (as `mod_php`) and uses `mpm_prefork` by default.

**The following modules have been added**

- msodbcsql, unixodbc
- oracle instant client
- extra fonts
- wkhtmltox
- php extensions (sqlsrv, oci8, pgsql, mysqli...)

## Copy default configuration files from container

```shell
docker run -d --rm --name test aniven/php:7.3-apache \
&& mkdir apache php \
&& docker cp -a test:/etc/apache2 ./apache/conf \
&& docker cp -a test:/usr/local/etc/php ./php/conf \
&& docker stop test
```

