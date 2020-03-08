# vim:set ft=dockerfile:
FROM postgres:12

ARG CDB_VALID_VERSION=0.36.0
ARG POSTGIS_VERSION=3.0.1
ARG GEOS_VERSION=3.5.2
ARG PROJ_VERSION=4.9.3
ARG GDAL_VERSION=2.2.4
ARG POSTGRES_USER=cartodb
ARG POSTGRES_PASSWORD=cartodb
ARG CRANKSHAFT_VERSION=0.9.0
ARG OBSERVATORY_VERSION=master

RUN localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8

ENV POSTGRES_USER=${POSTGRES_USER:-cartodb} \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-cartodb} \
    PGDATA=/var/lib/postgresql/data \
    LANG=en_US.utf8 \
    PGUSER=${POSTGRES_USER:-cartodb} \
    PYTHON3=true

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get remove -y python2.7 python2.7-minimal libpython2.7 libpython2.7-stdlib libpython2.7-minimal
RUN apt-get update --allow-unauthenticated --allow-insecure-repositories && apt-get install -y --no-install-recommends \
    build-essential software-properties-common \
    proj-bin proj-data libproj-dev \
    libjsoncpp1 libjsoncpp-dev \
    python-simplejson python3-pip python3-setuptools python3-dev python3-scipy \
    python3-sklearn python3-sklearn-lib \
    libgeos-c1v5 libgeos-dev libatlas-base-dev \
    gdal-bin libgdal-dev \
    libxml2-dev \
    postgis postgresql-12-postgis-3 postgresql-12-postgis-3-scripts \
    libpq5 libpq-dev \
    gfortran libopenblas-dev subversion libmkldnn-dev libsvmloc-dev \
    postgresql-contrib postgresql-server-dev-12 postgresql-plpython3-12 postgresql-12-plproxy \
    sudo ruby git wget && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 && \
    rm -rf /var/lib/apt/lists/* && \
    git clone git://github.com/CartoDB/cartodb-postgresql.git && \
    cd cartodb-postgresql && \
    git checkout $CDB_VALID_VERSION && \
    make all install && \
    cd /tmp && \
    git clone -- https://github.com/CartoDB/dataservices-api.git /tmp/dataservices-api && \
    cd /tmp/dataservices-api && \
    git checkout "pg12_migration" && \
    cd /tmp/dataservices-api/server/extension && \
    make all install && \
    cd /tmp/dataservices-api/client && \
    make all install && \
    cd /tmp/dataservices-api/server/lib/python/cartodb_services && \
    pip install wheel && \
    pip install -r requirements.txt && \
    pip install . --upgrade && \
    python setup.py install && \
    cd /tmp && \
    git clone https://github.com/CartoDB/data-services.git && \
    cd /tmp/data-services/geocoder/extension && \
    make install && \
    cd /tmp && \
    git clone https://github.com/CartoDB/crankshaft.git && \
    cd crankshaft && \
    git checkout $CRANKSHAFT_VERSION && \
    pip install numpy scipy joblib Cython && \
    ln -s /usr/include/locale.h /usr/include/xlocale.h
RUN export SKLEARN_VERSION=$(apt-cache policy python3-sklearn | grep 'Installed' | grep -oP '\d*\.\d*\.\d*') && \
    export SCIPY_VERSION=$(apt-cache policy python3-scipy | grep 'Installed' | grep -oP '\d*\.\d*\.\d*') && \
    export NUMPY_VERSION=$(apt-cache policy python3-numpy | grep 'Installed' | grep -oP '\d*\.\d*\.\d*') && \
    cd /tmp/crankshaft && \
    sed -i -r -e "s/'numpy==[0-9]+\.[0-9]+\.[0-9]+'/'numpy==${NUMPY_VERSION}'/1" src/py/crankshaft/setup.py && \
    sed -i -r -e "s/'scipy==[0-9]+\.[0-9]+\.[0-9]+'/'scipy==${SCIPY_VERSION}'/1" src/py/crankshaft/setup.py && \
    sed -i -r -e "s/'scikit-learn==[0-9]+\.[0-9]+\.[0-9]+'/'scikit-learn==${SKLEARN_VERSION}'/1" src/py/crankshaft/setup.py && \
    make install && \
    mkdir -p /docker-entrypoint-initdb.d
#
RUN cd /tmp && git clone --recursive https://github.com/CartoDB/observatory-extension.git && \
    cd observatory-extension && \
    git checkout $OBSERVATORY_VERSION && \
    make deploy

VOLUME /var/lib/postgresql/data

ADD ./cartodb.sh /docker-entrypoint-initdb.d/cartodb.sh
