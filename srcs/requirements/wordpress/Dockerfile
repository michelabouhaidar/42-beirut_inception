FROM alpine:3.20

RUN apk add --no-cache \
    php82 php82-fpm php82-mysqli php82-phar php82-mbstring \
    php82-json php82-curl php82-openssl php82-tokenizer \
    php82-xml php82-dom php82-session php82-iconv \
    mariadb-client curl bash \
    && ln -s /usr/bin/php82 /usr/bin/php

RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN mkdir -p /usr/src/wordpress /var/www/html /run/php \
    && php -d memory_limit=512M /usr/local/bin/wp core download --path=/usr/src/wordpress --allow-root

COPY conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY tools/script.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]