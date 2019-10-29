#!/usr/bin/env sh

set -ex

if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi


# allow the container to be started with `--user`
if [ "$1" = 'postgres' ] && [ "$(id -u)" = '0' ]; then
	mkdir -p "$PGDATA"
	chown -R postgres "$PGDATA"
	chmod 700 "$PGDATA"

	mkdir -p /var/run/postgresql
	chown -R postgres /var/run/postgresql
	chmod 775 /var/run/postgresql

	exec su-exec postgres "$0" "$@"
fi

if [ "$1" = 'postgres' ]; then
  mkdir -p "$PGDATA"
  chown -R postgres "$PGDATA"
  chmod 700 "$PGDATA"

	mkdir -p /var/run/postgresql
	chown -R postgres /var/run/postgresql
	chmod 775 /var/run/postgresql

  echo "Check need init for postgresql data"
  if [ ! -f $PGDATA/PG_VERSION ]; then
		if ! getent passwd "$(id -u)" &> /dev/null && [ -e /usr/lib/libnss_wrapper.so ]; then
      echo "WRAPPER"
			export LD_PRELOAD='/usr/lib/libnss_wrapper.so'
			export NSS_WRAPPER_PASSWD="$(mktemp)"
			export NSS_WRAPPER_GROUP="$(mktemp)"
			echo "postgres:x:$(id -u):$(id -g):PostgreSQL:$PGDATA:/bin/false" > "$NSS_WRAPPER_PASSWD"
			echo "postgres:x:$(id -g):" > "$NSS_WRAPPER_GROUP"
		fi

    initdb -U postgres -k "$PGDATA"

    # unset/cleanup "nss_wrapper" bits
		if [ "${LD_PRELOAD:-}" = '/usr/lib/libnss_wrapper.so' ]; then
			rm -f "$NSS_WRAPPER_PASSWD" "$NSS_WRAPPER_GROUP"
			unset LD_PRELOAD NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP
		fi

    sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" "$PGDATA/postgresql.conf"

    export POSTGRES_USER=${POSTGRES_USER:-cartodb}
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-cartodb}
    export POSTGRES_DB=${POSTGRES_DB:-cartodb}

    {
			echo
			echo "host all all all md5"
		} >> "$PGDATA/pg_hba.conf"

    echo "Create new database if not exists"
    PG_USER=postgresq pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start

    if ! psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
      echo "Prepare database"
      psql -U postgres -Atc "create user publicuser nocreaterole nocreatedb nosuperuser;"
      psql -U postgres -Atc "create user tileuser nocreaterole nocreatedb nosuperuser;"

      psql -U postgres -Atc "create database template_postgis owner postgres template template0 encoding UTF8;"
      psql -U postgres template_postgis -c "create extension postgis; create extension postgis_topology;"

      psql -U postgres -Atc "create user $POSTGRES_USER with encrypted password '$POSTGRES_PASSWORD';"
      psql -U postgres -Atc "create database $POSTGRES_DB with owner $POSTGRES_USER encoding 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' template template0;"
      psql -U postgres -Atc "alter user $POSTGRES_USER with superuser;"

      for ext in postgis plpythonu cartodb postgis_topology fuzzystrmatch postgis_tiger_geocoder uuid-ossp; do
        psql -U "$POSTGRES_USER" "$POSTGRES_DB" -Atc "create extension if not exists \"${ext}\" ;";
      done
    fi
    PG_USER=postgres pg_ctl -D "$PGDATA" -m fast -w stop
  fi
fi

exec "$@"
