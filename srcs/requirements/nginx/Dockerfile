FROM debian:bookworm-20260406

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends nginx ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY default /etc/nginx/sites-available/default
COPY ssl/mabou-ha.crt /etc/nginx/ssl/nginx.crt
COPY ssl/mabou-ha.key /etc/nginx/ssl/nginx.key

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]