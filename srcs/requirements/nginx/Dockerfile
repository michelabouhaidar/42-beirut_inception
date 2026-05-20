FROM alpine:3.20

RUN apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl /run/nginx \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
       -keyout /etc/nginx/ssl/nginx.key \
       -out /etc/nginx/ssl/nginx.crt \
       -subj "/C=LB/ST=Beirut/L=Beirut/O=42/CN=mabou-ha.42.fr"

COPY conf/default /etc/nginx/http.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]