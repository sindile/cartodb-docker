#!/bin/bash
set -ex

# sudo ldconfig

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

sed -i 's/\(peer\|md5\)/trust/' "$PGDATA/pg_hba.conf"
pg_ctl reload
psql -U "$PGUSER" -v ON_ERROR_STOP=1 -Atc "SELECT pg_reload_conf();"

echo "Creating user 'publicuser'..."
createuser publicuser --no-createrole --no-createdb --no-superuser -U $PGUSER
echo "Creating user 'tileuser'..."
createuser tileuser --no-createrole --no-createdb --no-superuser -U $PGUSER

# Initialize template_postgis database. We create a template database in postgresql that will
# contain the postgis extension. This way, every time CartoDB creates a new user database it just
# clones this template database
# psql -U "$PGUSER" -v ON_ERROR_STOP=1 -Atc "alter database template_postgis SET search_path TO \"\$user\",public,cartodb,template_postgis,cdb_dataservices_client;"
# psql -U $PGUSER postgis -v ON_ERROR_STOP=1 -c 'CREATE EXTENSION postgis;'

echo "Creating user 'geocoder'..."
createuser geocoder --login --superuser -U $PGUSER
createdb -U $PGUSER -E UTF8 -O geocoder geocoder

echo "Setup Postgis"

POSTGIS_SQL_PATH=`pg_config --sharedir`/contrib/postgis-2.4;
psql -U "$PGUSER" -v ON_ERROR_STOP=1 -Atc "alter database $POSTGRES_DB SET search_path TO \"\$user\",public,cartodb,postgis,cdb_dataservices_client;"
psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='$POSTGRES_DB'"
psql -c "DROP EXTENSION IF EXISTS cartodb CASCADE;"
psql -c "DROP EXTENSION IF EXISTS cdb_geocoder CASCADE;"
psql -c "DROP EXTENSION IF EXISTS plproxy CASCADE;"
psql -c "DROP EXTENSION IF EXISTS cdb_dataservices_server CASCADE;"
psql -c "DROP EXTENSION IF EXISTS cdb_dataservices_client CASCADE;"
psql -c "DROP SCHEMA IF EXISTS cdb_dataservices_client CASCADE;"
psql -c "DROP USER IF EXISTS publicuser;"
psql -c "CREATE EXTENSION plproxy;"
psql -c "CREATE EXTENSION plpython3u;"
psql -c "CREATE EXTENSION postgis SCHEMA public;"
psql -c "CREATE EXTENSION postgis_raster SCHEMA public;"
psql -c "CREATE EXTENSION postgis_topology;"
psql -c "CREATE USER publicuser;"
psql -c "GRANT ALL ON geometry_columns TO public;"
psql -c "GRANT ALL ON spatial_ref_sys TO public;"
psql -c "GRANT ALL ON geometry_columns TO $POSTGRES_DB;"
psql -c "GRANT ALL ON spatial_ref_sys TO $POSTGRES_DB;"
psql -c "CREATE EXTENSION cartodb;"
psql -c "CREATE EXTENSION crankshaft version dev;"
psql -c "CREATE EXTENSION cdb_geocoder SCHEMA public;"
psql -c "CREATE EXTENSION cdb_dataservices_server;"
psql -c "CREATE EXTENSION cdb_dataservices_client;"

# for ext in plpythonu postgis cartodb cdb_geocoder plproxy cdb_dataservices_server cdb_dataservices_client; do
#   echo "Creating extension ${ext} on database 'geocoder'"
#   psql -U "$geocoder" "geocoder" -v ON_ERROR_STOP=1 -Atc "create extension if not exists \"${ext}\" ;";
# done

# echo "Creating database 'template_postgis'..."
createdb -T template0 -O $PGUSER -U $PGUSER -E UTF8 template_postgis
echo "Creating extensions 'postgis' and 'postgis_topology' on database 'template_postgis'..."
for ext in postgis postgis_raster postgis_topology fuzzystrmatch postgis_tiger_geocoder "crankshaft version dev"; do # uuid-ossp cartodb; do
  echo "Creating extension ${ext} on database template_postgis"
  psql -U "$PGUSER" template_postgis -v ON_ERROR_STOP=1 -Atc "create extension if not exists ${ext} cascade;";
done

echo "Creating database 'dataservices_db'..."
createdb -T template0 -O $PGUSER -U $PGUSER -E UTF8 dataservices_db
for ext in cdb_dataservices_server; do
  echo "Creating extension ${ext} on database 'dataservices_db'"
  psql -U "$PGUSER" dataservices_db -Atc "create extension if not exists \"${ext}\" CASCADE;";
done
echo "Configure dataservices_db'..."
cat <<-CONFIG_SQL | tr -d '\n' | psql -U "$PGUSER" dataservices_db
  SELECT CDB_Conf_SetConf('redis_metadata_config', '{"redis_host": "$REDIS_HOST", "redis_port": 6379, "sentinel_master_id": "", "timeout": 0.1, "redis_db": 5}');
  SELECT CDB_Conf_SetConf('redis_metrics_config', '{"redis_host": "$REDIS_HOST", "redis_port": 6379, "sentinel_master_id": "", "timeout": 0.1, "redis_db": 5}');
  SELECT CDB_Conf_SetConf('heremaps_conf', '{"geocoder": {"app_id": "$HERE_APP_ID", "app_code": "$HERE_APP_CODE", "geocoder_cost_per_hit": "1"}, "isolines" : {"app_id": "$HERE_APP_ID", "app_code": "$HERE_APP_CODE"}}');
  SELECT CDB_Conf_SetConf('mapbox_conf', '{"routing": {"api_keys": ["$MAPBOX_API_TOKEN"], "monthly_quota": 999999}, "geocoder": {"api_keys": ["$MAPBOX_API_TOKEN"], "monthly_quota": 999999}, "matrix": {"api_keys": ["$MAPBOX_API_TOKEN"], "monthly_quota": 1500000}}');
  SELECT CDB_Conf_SetConf('tomtom_conf', '{"routing": {"api_keys": ["$TOMTOM_API_TOKEN"], "monthly_quota": 999999}, "geocoder": {"api_keys": ["$TOMTOM_API_TOKEN"], "monthly_quota": 999999}, "isolines": {"api_keys": ["$TOMTOM_API_TOKEN"], "monthly_quota": 1500000}}');
CONFIG_SQL
