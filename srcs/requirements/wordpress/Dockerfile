FROM debian:trixie

RUN apt-get update \
 && apt-get install -y --no-install-recommends php-fpm php-mysqli curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY www.conf /etc/php/8.4/fpm/pool.d/www.conf
COPY script.sh /usr/local/bin/wp-entrypoint.sh

RUN chmod +x /usr/local/bin/wp-entrypoint.sh \
 && mkdir -p /run/php /var/www/html

ENTRYPOINT ["sh", "/usr/local/bin/wp-entrypoint.sh"]
CMD ["php-fpm8.4", "-F"]