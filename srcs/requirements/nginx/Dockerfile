FROM debian:trixie

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx ca-certificates openssl \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY ssl/mabou-ha.crt /etc/nginx/ssl/mabou-ha.crt
COPY ssl/mabou-ha.key /etc/nginx/ssl/mabou-ha.key
COPY default /etc/nginx/sites-available/default

CMD ["nginx", "-g", "daemon off;"]