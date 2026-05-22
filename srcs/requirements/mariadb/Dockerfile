FROM alpine:3.22

RUN apk add --no-cache mariadb mariadb-client \
    && rm /etc/my.cnf.d/mariadb-server.cnf

COPY conf/50-server.cnf /etc/my.cnf.d/50-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mysqld"]