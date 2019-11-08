# vim:set ft=dockerfile:
FROM postgres:10

ARG CDB_VALID_VERSION=0.31.0
ARG POSTGIS_VERSION=2.4.8
ARG GEOS_VERSION=3.5.2
ARG PROJ_VERSION=4.9.3
ARG GDAL_VERSION=2.2.4
ARG POSTGRES_USER=cartodb
ARG POSTGRES_PASSWORD=cartodb

RUN localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

ENV POSTGRES_USER=${POSTGRES_USER:-cartodb} \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-cartodb} \
    PGDATA=/var/lib/postgresql/data \
    LANG=en_US.utf8 \
    PGUSER=${POSTGRES_USER:-cartodb}

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    software-properties-common \
    proj-bin proj-data libproj-dev \
    libjsoncpp1 libjsoncpp-dev python-simplejson \
    libgeos-c1v5 libgeos-dev \
    gdal-bin libgdal-dev \
    libxml2-dev \
    liblwgeom-2.3.0 postgis postgresql-10-postgis-2.4 postgresql-10-postgis-2.4-scripts \
    libpq5 libpq-dev \
    postgresql-contrib postgresql-server-dev-10 postgresql-plpython-10 \
    sudo \
    git && \
    rm -rf /var/lib/apt/lists/* && \
    git clone --depth 1 --branch $CDB_VALID_VERSION git://github.com/CartoDB/cartodb-postgresql.git && \
    cd cartodb-postgresql && \
    make all install && \
    mkdir -p /docker-entrypoint-initdb.d

VOLUME /var/lib/postgresql/data

ADD ./cartodb.sh /docker-entrypoint-initdb.d/cartodb.sh
