FROM alpine:3.22

RUN apk add --no-cache \
    php83 php83-fpm php83-mysqli php83-phar php83-mbstring \
    php83-json php83-curl php83-openssl php83-tokenizer \
    php83-xml php83-dom php83-session php83-iconv \
    mariadb-client curl bash

RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /usr/src/wordpress /var/www/html /run/php \
    && php -d memory_limit=512M /usr/local/bin/wp core download --path=/usr/src/wordpress --allow-root

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/script.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]