# vim:set ft=dockerfile:

FROM alpine:3.4 AS source

ARG APP_ENV=production
ARG CARTODB_VERSION=4.35.0

COPY ./grunt_production.json /grunt_production.json
RUN apk add --no-cache --upgrade git && \
    git clone --recursive -- https://github.com/CartoDB/cartodb.git /app && \
    cd /app && \
    git checkout "v$CARTODB_VERSION" && \
    mv /grunt_production.json /app/config && \
    tar -czvf app.tar.gz Gemfile Gemfile.lock config.ru Rakefile \
                         package.json package-lock.json carto-package.json bower.json Gruntfile.js \
                         vendor/assets \
                         spec/support/factories/tables.rb \
                         spec/helpers/unique_names_helper.rb \
                         app config db lib gears services assets script webpack public .git

FROM osgeo/gdal:ubuntu-small-latest AS base

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
    CADDYPATH=/var/lib/caddy \
    NODE_VERSION=10.19.0 \
    NVM_DIR=/usr/local/nvm \
    RUBY_VERSION=2.4.9 \
    PATH=/root/.rbenv/shims:/root/.rbenv/bin:/root/.rbenv/plugins/ruby-build/bin:$PATH
WORKDIR /app

COPY --from=source /app/app.tar.gz /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates gnupg wget && \
    rm -rf /var/lib/apt/lists/* && \
    key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' && \
	  export GNUPGHOME="$(mktemp -d)" && \
	  gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" && \
	  gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg && \
	  command -v gpgconf > /dev/null && gpgconf --kill all && \
	  rm -rf "$GNUPGHOME" && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                                   build-essential\
                                   ca-certificates \
                                   net-tools \
                                   git wget netcat \
                                   libssl-dev libreadline-dev zlib1g-dev \
                                   libpq5 libpq-dev \
                                   libicu-dev tzdata && \
    git clone git://github.com/sstephenson/rbenv.git ~/.rbenv && \
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    mkdir -p $NVM_DIR && \
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    gem install -V -n /usr/local/bin --no-document compass && \
    mkdir -p config && \
    curl -sfSL "https://caddyserver.com/download/linux/amd64?plugins=${CADDY_PLUGINS}&license=personal&telemetry=off" | tar -xz -C /tmp && \
    mv /tmp/caddy /usr/bin/caddy && \
    cd /app && \
    tar -xzvf app.tar.gz && \
    rm -rf app.tar.gz && \
    npm config set loglevel info && \
    compass --version && \
    NODE_ENV=development npm install --verbose && \
    npm run carto-node && \
    npm run build:static && \
    ./node_modules/grunt-cli/bin/grunt --environment=${NODE_ENV}

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    gem install --no-ri --no-rdoc -n /usr/local/bin bundler -v 1.17.3 && \
    gem install --no-ri --no-rdoc -n /usr/local/bin bigdecimal && \
    bundle --deployment --path /vendor/ --without development test

ENV ENV=/root/.profile
RUN echo ". '$NVM_DIR/nvm.sh'" >> /root/.profile

COPY ./Caddyfile /etc/caddy/
COPY ./monkey_patches.rb /app/config/initializers/zz_monkey_patches.rb
VOLUME /uploads

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh", "-l", "-c", "bundle exec unicorn -d -p 80"]
