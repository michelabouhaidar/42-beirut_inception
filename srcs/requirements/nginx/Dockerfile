FROM debian:bookworm-20260406

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends nginx ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout /etc/nginx/ssl/nginx.key \
       -out /etc/nginx/ssl/nginx.crt \
       -subj "/C=LB/ST=Beirut/L=Beirut/O=42/CN=mabou-ha.42.fr"

COPY conf/default /etc/nginx/sites-available/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]