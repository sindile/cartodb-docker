# vim:set ft=dockerfile:

FROM alpine:3.4 AS source

ARG CARTODB_VERSION=master

COPY ./grunt_production.json /grunt_production.json
RUN apk add --no-cache --upgrade git && \
    git clone --recursive -b $CARTODB_VERSION -- https://github.com/CartoDB/cartodb.git /app && \
    cd /app && \
    mv /grunt_production.json /app/config && \
    tar -czvf app.tar.gz Gemfile Gemfile.lock config.ru Rakefile \
                         package.json package-lock.json carto-package.json bower.json Gruntfile.js \
                         vendor/assets \
                         spec/support/factories/tables.rb \
                         spec/helpers/unique_names_helper.rb \
                         app config db lib gears services assets script webpack public .git

FROM osgeo/gdal:alpine-small-latest AS base

ARG APP_ENV=production
ARG CADDY_PLUGINS=http.cors,http.minify

ENV RAILS_ENV=${APP_ENV} \
    RACK_ENV=${APP_ENV} \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    NODE_ENV=${APP_ENV} \
    BUNDLE_PATH=/vendor \
    GEM_HOME=/vendor \
    BUNDLE_BIN=/vendor/bin \
    PATH=$PATH:/vendor/bin \
    APP_ROOT=/app \
    RAILS_LOG_BASE_PATH=/app/log/ \
    RAILS_PUBLIC_UPLOADS_PATH=/uploads \
    CADDYPATH=/var/lib/caddy

WORKDIR /app

COPY --from=source /app/app.tar.gz /app

RUN apk add --no-cache --upgrade build-base \
                                git \
                                python \
                                py2-pip \
                                ruby \
                                ruby-dev \
                                ruby-bigdecimal \
                                ruby-webrick \
                                ruby-etc \
                                postgresql-dev \
                                nodejs \
                                npm \
                                tzdata \
                                git \
                                icu-dev \
                                curl \
                                zlib-dev \
                                linux-headers \
                                ca-certificates && \
    gem install --no-document compass && \
    mkdir -p config && \
    ARCH=$(apk --print-arch | sed 's/x86_64/amd64/') && \
    curl -sfSL "https://caddyserver.com/download/linux/${ARCH}?plugins=${CADDY_PLUGINS}&license=personal&telemetry=off" | tar -xz -C /tmp && \
    mv /tmp/caddy /usr/bin/caddy && \
    cd /app && \
    tar -xzvf app.tar.gz && \
    rm -rf app.tar.gz && \
    npm config set loglevel info && \
    NODE_ENV=development npm install --verbose && \
    npm run carto-node && \
    npm run build:static && \
    ./node_modules/grunt-cli/bin/grunt --environment=${NODE_ENV}

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    gem install --no-ri --no-rdoc bundler -v 1.17.3 && \
    gem install --no-ri --no-rdoc bigdecimal && \
    bundle --deployment --path /vendor/ --without development test

COPY ./Caddyfile /etc/caddy/
COPY ./monkey_patches.rb /app/config/initializers/zz_monkey_patches.rb
VOLUME /uploads

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["unicorn", "-d", "-p", "80"]
