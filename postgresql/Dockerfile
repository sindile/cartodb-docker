# vim:set ft=dockerfile:
# FROM alpine:edge
FROM postgres:10-alpine

ARG CDB_VALID_VERSION=0.31.0
ARG POSTGIS_VERSION=2.4.8
ARG GEOS_VERSION=3.5.2
ARG PROJ_VERSION=4.9.3
ARG GDAL_VERSION=2.2.4

ENV PGDATA=/var/lib/postgresql/data \
    LANG=en_US.utf8 \
    PGUSER=postgres

WORKDIR /tmp

RUN set -ex && \
    apk add --no-cache --update --virtual .fetch-deps \
            build-base \
            linux-headers \
            ca-certificates \
            wget \
            bash \
            ruby \
            python2-dev \
            automake \
            libtool \
            autoconf \
            curl \
            unzip \
            libxml2-dev \
            libxml2-utils \
            git \
            g++ zlib-dev zstd-dev libjpeg-turbo-dev libpng-dev libwebp-dev expat-dev postgresql-dev openjpeg-dev \
            json-c-dev

RUN git clone -b $PROJ_VERSION https://github.com/OSGeo/PROJ.git && \
    cd PROJ && \
    ./autogen.sh && \
    ./configure --prefix=/usr --disable-static --enable-lto && \
    make -j$(nproc) && \
    make check && \
    make install && \
    mkdir -p /usr/share/proj && \
    curl -LOs https://download.osgeo.org/proj/proj-datumgrid-1.8.zip &&  unzip -j -u -o proj-datumgrid-1.8.zip  -d /usr/share/proj && \
    curl -LOs https://download.osgeo.org/proj/proj-datumgrid-europe-1.2.zip &&  unzip -j -u -o proj-datumgrid-europe-1.2.zip -d /usr/share/proj && \
    curl -LOs https://download.osgeo.org/proj/proj-datumgrid-oceania-1.0.zip &&  unzip -j -u -o proj-datumgrid-oceania-1.0.zip -d /usr/share/proj && \
    curl -LOs https://download.osgeo.org/proj/proj-datumgrid-world-1.0.zip &&  unzip -j -u -o proj-datumgrid-world-1.0.zip -d /usr/share/proj && \
    curl -LOs https://download.osgeo.org/proj/proj-datumgrid-north-america-1.2.zip &&  unzip -j -u -o proj-datumgrid-north-america-1.2.zip -d /usr/share/proj && \
    rm *.zip

RUN cd /tmp && \
    git clone -b v$GDAL_VERSION https://github.com/OSGeo/gdal.git

RUN cd /tmp/gdal/gdal && \
    ./configure --prefix=/usr --without-libtool \
                --with-hide-internal-symbols \
                --with-proj=/usr \
                --with-libtiff=internal --with-rename-internal-libtiff-symbols \
                --with-geotiff=internal --with-rename-internal-libgeotiff-symbols \
                --disable-all-optional-drivers \
                --enable-driver-shape \
                --enable-driver-gpkg \
                --with-webp \
                --without-jpeg12 \
                --without-pcraster \
                --without-pcidsk \
                --without-lerc \
                --without-gnm \
                --without-gif && \
    make -j$(nproc) && \
    make install

RUN cd /tmp && \
    git clone -b $GEOS_VERSION https://git.osgeo.org/gitea/geos/geos.git && \
    cd geos && \
    ./autogen.sh && \
    ./configure  && \
    make && \
    make install

RUN cd /tmp/ && wget https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz && \
    tar -xvzf $POSTGIS_VERSION.tar.gz -C /tmp  && \
    cd /tmp/postgis-$POSTGIS_VERSION && \
    ./autogen.sh && \
    ./configure
    #     make && \
    #     make check && \
    #     make install && \
    #     \
    #     export PG_CONF_DIR=$(pg_config --sysconfdir) && \
    #     mkdir -p "$PG_CONF_DIR" && \
    #     mkdir -p "$PGDATA" && \
    #     chown -R postgres:postgres "$PGDATA" && \
    #     chmod 777 "$PGDATA" && \
    #     \
    #     git clone -b $CDB_VALID_VERSION https://github.com/CartoDB/cartodb-postgresql.git && \
    #     cd cartodb-postgresql && \
    #     make all install && \
    #     \
    #     cd /tmp && \
    #     wget https://bootstrap.pypa.io/get-pip.py -O get-pip.py && \
    #     python get-pip.py && \
    #     pip install hiredis && \
    #     \
    #     git clone https://github.com/CartoDB/dataservices-api.git && \
    #     cd /tmp/dataservices-api/client && \
    #     make install && \
    #     cd /tmp/dataservices-api/server/extension && \
    #     make install && \
    #     cd /tmp/dataservices-api/server/lib/python/cartodb_services && \
    #     pip install -r requirements.txt && \
    #     pip install . --upgrade && \
    #     \
    #     apk del .fetch-deps && \
    #     ln -sf /dev/stdout /var/log/postgresql/postgresql.log
    #
    # RUN apk add --repository http://nl.alpinelinux.org/alpine/edge/testing --no-cache --update proj-dev
    #
    # COPY deployment/postgresql/docker-entrypoint.sh /usr/local/bin/
    # COPY deployment/postgresql/pg_hba.conf /tmp/pg_hba.conf
    # RUN  chmod +x /usr/local/bin/docker-entrypoint.sh && \
    #      cp /tmp/pg_hba.conf $(pg_config --sysconfdir)/pg_hba.conf
    #
    # VOLUME /var/lib/postgresql/data
    # EXPOSE 5432
    #
    # ENTRYPOINT ["docker-entrypoint.sh"]
    # CMD ["postgres"]
