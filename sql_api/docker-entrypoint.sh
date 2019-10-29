#!/usr/bin/env sh

set -ex
CARTODB_DOMAIN_REGEXP=$(echo "$CARTODB_DOMAIN" | sed 's/[-.]/\\\0/')

echo "Setup config/environments/production.js"
cat <<EOT >> config/environments/production.js
module.exports.gc_interval = 10000;
// In case the base_url has a :user param the username will be the one specified in the URL,
// otherwise it will fallback to extract the username from the host header.
module.exports.base_url     = '(?:/api/:version|/user/:user/api/:version)';
module.exports.useProfiler = true;
module.exports.log_format   = '[:date] :remote-addr :method :req[Host]:url :status :response-time ms -> :res[Content-Type] (:res[X-SQLAPI-Profiler]) (:res[X-SQLAPI-Errors]) (:res[X-SQLAPI-Log])';
module.exports.log_filename = '/dev/stdout';
module.exports.user_from_host = '^(.*)\\.${CARTODB_DOMAIN_REGEXP}$';
module.exports.node_port    = 80;
module.exports.node_host    = '0.0.0.0';
module.exports.node_socket_timeout    = 600000;
module.exports.environment  = '${APP_ENV}';

module.exports.db_base_name = 'cartodb_user_<%= user_id %>_db';
module.exports.db_user      = 'cartodb_user_<%= user_id %>';
module.exports.db_user_pass = '<%= user_password %>'
module.exports.db_pubuser   = 'publicuser';

// Password for the anonymous PostgreSQL user
module.exports.db_pubuser_pass   = 'public';
module.exports.db_host      = '${POSTGRES_HOST}';
module.exports.db_port      = '5432';
module.exports.db_batch_port      = '5432';

module.exports.finished_jobs_ttl_in_seconds = 2 * 3600; // 2 hours
module.exports.batch_query_timeout = 12 * 3600 * 1000; // 12 hours in milliseconds
module.exports.batch_log_filename = 'logs/batch-queries.log';
module.exports.copy_timeout = "'5h'";
module.exports.copy_from_max_post_size = 2 * 1024 * 1024 * 1024 // 2 GB;
module.exports.copy_from_max_post_size_pretty = '2 GB';
module.exports.copy_from_minimum_input_speed = 0; // 1 byte per second
module.exports.copy_from_maximum_slow_input_speed_interval = 15 // 15 seconds
module.exports.batch_max_queued_jobs = 64;
module.exports.batch_capacity_strategy = 'fixed';
module.exports.batch_capacity_fixed_amount = 4;
module.exports.batch_capacity_http_url_template = 'http://<%= dbhost %>:9999/load';
module.exports.db_pool_size = 500;
module.exports.db_pool_idleTimeout = 30000;
module.exports.db_pool_reapInterval = 1000;
//module.exports.db_max_row_size = 10 * 1024 * 1024;
module.exports.db_use_config_object = true;
module.exports.db_keep_alive = {
    enabled: true,
    initialDelay: 5000 // Not used yet
};
module.exports.redis_host   = '${REDIS_HOST}';
module.exports.redis_port   = 6379;
module.exports.redisPool    = 50;
module.exports.redisIdleTimeoutMillis   = 10000;
module.exports.redisReapIntervalMillis  = 1000;
module.exports.redisLog     = false;

module.exports.tmpDir = '/tmp';
module.exports.ogr2ogrCommand = 'ogr2ogr';
module.exports.zipCommand = 'zip';
module.exports.statsd = {
  host: 'localhost',
  port: 8125,
  prefix: 'dev.:host.',
  cacheDns: true
  // support all allowed node-statsd options
};
module.exports.health = {
    enabled: true,
    username: 'development',
    query: 'select 1'
};
module.exports.oauth = {
    allowedHosts: ['${CARTODB_DOMAIN}']
};
module.exports.disabled_file = 'pids/disabled';

module.exports.ratelimits = {
  // whether it should rate limit endpoints (global configuration)
  rateLimitsEnabled: false,
  // whether it should rate limit one or more endpoints (only if rateLimitsEnabled = true)
  endpoints: {
    query: false,
    job_create: false,
    job_get: false,
    job_delete: false,
    copy_from: false,
    copy_to: false
  }
}

module.exports.validatePGEntitiesAccess = false;
module.exports.dataIngestionLogPath = 'logs/data-ingestion.log';
module.exports.logQueries = true;
module.exports.maxQueriesLogLength = 1024;

module.exports.cache = {
  ttl: 60 * 60 * 24 * 365, // one year in seconds
  fallbackTtl: 60 * 5 // five minutes in seconds
};
EOT

echo "Run APP"
exec "$@"
