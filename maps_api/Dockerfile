# vim:set ft=dockerfile:
FROM node:10-buster-slim AS build

ARG APP_ENV=production
ARG MAPS_API_VERSION=7.1.0
ARG MAPNIK_VERSION=v3.0.22
ARG MAPNIK_NODE_VERSION=v3.6.2
ARG CAMSHAFT_VERSION=0.65.2

ENV NODE_ENV=$APP_ENV \
    PATH=$PATH:/vendor/bin \
    APP_ROOT=/app

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates gnupg wget && \
    rm -rf /var/lib/apt/lists/* && \
    key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' && \
	  export GNUPGHOME="$(mktemp -d)" && \
	  gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" && \
	  gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg && \
	  command -v gpgconf > /dev/null && gpgconf --kill all && \
	  rm -rf "$GNUPGHOME"
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      libpixman-1-0 libpixman-1-dev \
      libcairo2-dev libjpeg-dev libgif-dev libpango1.0-dev \
      git \
      libpq5 \
      g++ \
      libsqlite3-dev \
      python \
      make \
      libgdal-dev \
      libboost-filesystem-dev \
      libboost-program-options-dev \
      libboost-python-dev libboost-regex-dev \
      libboost-system-dev libboost-thread-dev \
      libicu-dev \
      python-dev libxml2 libxml2-dev \
      libfreetype6 libfreetype6-dev \
      libjpeg-dev \
      libpng-dev \
      libproj-dev \
      libtiff-dev \
      libcairo2-dev python-cairo-dev \
      libcairomm-1.0-dev \
      build-essential python-nose \
      python-gdal \
      libharfbuzz-dev \
      postgresql-server-dev-12 postgresql-contrib postgresql-12-postgis-3-scripts \
      libmapnik-dev libmapnik3.0 mapnik-vector-tile python3-mapnik \
      node-mapnik

RUN git clone https://github.com/CartoDB/Windshaft-cartodb.git /app && \
    cd /app && \
    git checkout $MAPS_API_VERSION && \
    npm config set loglevel info && \
    npm install --verbose

RUN git clone https://github.com/CartoDB/camshaft.git /tmp/camshaft && \
    cd /tmp/camshaft && \
    git checkout $CAMSHAFT_VERSION && \
    npm config set loglevel info && \
    npm install --verbose

WORKDIR /app

RUN sh -c "npm install --verbose"

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh", "-c", "node app.js $APP_ENV"]
