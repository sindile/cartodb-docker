FROM alpine:3.4

ARG CADDY_PLUGINS=http.cors,http.minify
ENV CADDYPATH /var/lib/caddy

RUN ARCH=$(apk --print-arch | sed 's/x86_64/amd64/') && \
  apk --no-cache add curl ca-certificates git && \
  curl -sfSL "https://caddyserver.com/download/linux/$ARCH?plugins=$CADDY_PLUGINS&license=personal&telemetry=off" \
    | tar -xz -C /tmp && \
  mv /tmp/caddy /usr/bin/caddy

#COPY ./Caddyfile /etc/caddy/
COPY Caddyfile /etc/caddy/

EXPOSE 80 443
CMD ["caddy", "-conf", "/etc/caddy/Caddyfile"]
