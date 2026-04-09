FROM debian:bookworm-20260406

RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client curl ca-certificates \
    php7.4-fpm php7.4-mysql php7.4-cli php7.4-curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN wp core download --path=/usr/src/wordpress --allow-root

RUN mkdir -p /var/www/html /run/php

COPY www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY script.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]