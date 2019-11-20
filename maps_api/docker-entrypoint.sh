#!/usr/bin/env sh

set -ex

echo "Setup config/environments/production.js"
cat <<EOT >> config/environments/production.js
var config = {
    environment: '${APP_ENV}'
    ,port: 80
    ,host: '0.0.0.0'
    ,uv_threadpool_size: undefined
    ,gc_interval: 10000
    ,user_from_host: '^(.*)$'
    ,routes: {
        v1: {
            paths: [
                '/api/v1',
                '/user/:user/api/v1',
            ],
            map: {
                paths: [
                    '/map',
                ]
            },
            template: {
                paths: [
                    '/map/named'
                ]
            }
        },
        v0: {
            paths: [
                '/tiles'
            ],
            map: {
                paths: [
                    '/layergroup'
                ]
            },
            template: {
                paths: [
                    '/template'
                ]
            }
        }
    }
    ,resources_url_templates: {
        http: 'http://{{=it.cdn_url}}/{{=it.user}}/api/v1/map',
        https: 'https://{{=it.cdn_url}}/{{=it.user}}/api/v1/map'
    }
    ,maxConnections:128
    ,maxUserTemplates:1024
    ,mapConfigTTL: 7200
    ,socket_timeout: 600000
    ,enable_cors: true
    ,cache_enabled: true
    ,log_format: ':req[X-Real-IP] :method :req[Host]:url :status :response-time ms -> :res[Content-Type] (:res[X-Tiler-Profiler]) (:res[X-Tiler-Errors])'
    ,log_filename: undefined
    ,postgres_auth_user: 'cartodb_user_<%= user_id %>'
    ,postgres_auth_pass: '<%= user_password %>'
    ,postgres: {
        type: "postgis",
        user: "publicuser",
        password: "public",
        host: '${POSTGRES_HOST}',
        port: 5432,
        pool: {
            size: 16,
            idleTimeout: 3000,
            reapInterval: 1000
        },
        simplify_geometries: true,
        persist_connection: false,
        use_overviews: true
    }
    ,mapnik_version: undefined
    ,mapnik_tile_format: 'png8:m=h'
    ,statsd: {
        host: 'localhost',
        port: 8125,
        prefix: ':host.', // could be hostname, better not containing dots
        cacheDns: true
        // support all allowed node-statsd options
    }
    ,renderer: {
      // Milliseconds since last access before renderer cache item expires
      cache_ttl: 60000,
      statsInterval: 5000, // milliseconds between each report to statsd about number of renderers and mapnik pool status
      mvt: {
        //If enabled, MVTs will be generated with PostGIS directly
        //If disabled, MVTs will be generated with Mapnik MVT
        usePostGIS: true
      },
      mapnik: {
          poolSize: 8,
          poolMaxWaitingClients: 64,
          useCartocssWorkers: false,
          metatile: 2,
          metatileCache: {
              ttl: 0,
              deleteOnHit: false
          },

          // Override metatile behaviour depending on the format
          formatMetatile: {
              png: 2,
              'grid.json': 1
          },

          // Buffer size is the tickness in pixel of a buffer
          // around the rendered (meta?)tile.
          //
          // This is important for labels and other marker that overlap tile boundaries.
          // Setting to 128 ensures no render artifacts.
          // 64 may have artifacts but is faster.
          // Less important if we can turn metatiling on.
          bufferSize: 64,

          // SQL queries will be wrapped with ST_SnapToGrid
          // Snapping all points of the  geometry to a regular grid
          snapToGrid: false,

          // SQL queries will be wrapped with ST_ClipByBox2D
          // Returning the portion of a geometry falling within a rectangle
          // It will only work if snapToGrid is enabled
          clipByBox2d: true,

          postgis: {
              // Parameters to pass to datasource plugin of mapnik
              // See http://github.com/mapnik/mapnik/wiki/PostGIS
              user: "publicuser",
              password: "public",
              host: '127.0.0.1',
              port: 5432,
              extent: "-20037508.3,-20037508.3,20037508.3,20037508.3",
              // max number of rows to return when querying data, 0 means no limit
              row_limit: 65535,
              /*
               * Set persist_connection to false if you want
               * database connections to be closed on renderer
               * expiration (1 minute after last use).
               * Setting to true (the default) would never
               * close any connection for the server's lifetime
               */
               persist_connection: false,
               simplify_geometries: true,
               use_overviews: true, // use overviews to retrieve raster
               max_size: 500,
               twkb_encoding: true
          },

          limits: {
              render: 0,
              cacheOnTimeout: true
          },

          // If enabled Mapnik will reuse the features retrieved from the database
          // instead of requesting them once per style inside a layer
          'cache-features': true,

          // Require metrics to the renderer
          metrics: false,

          // Options for markers attributes, ellipses and images caches
          markers_symbolizer_caches: {
              disabled: false
          }
      },
      http: {
          timeout: 2000, // the timeout in ms for a http tile request
          proxy: undefined, // the url for a proxy server
          whitelist: [ // the whitelist of urlTemplates that can be used
              '.*', // will enable any URL
              'http://{s}.example.com/{z}/{x}/{y}.png'
          ],
          // image to use as placeholder when urlTemplate is not in the whitelist
          // if provided the http renderer will use it instead of throw an error
          fallbackImage: {
              type: 'fs', // 'fs' and 'url' supported
              src: __dirname + '/../../assets/default-placeholder.png'
          }
      },
      torque: {}
    }
    // anything analyses related
    ,analysis: {
        // batch configuration
        batch: {
            // Inline execution avoid the use of SQL API as batch endpoint
            // When set to true it will run all analysis queries in series, with a direct connection to the DB
            // This might be useful for:
            //  - testing
            //  - running an standalone server without any dependency on external services
            inlineExecution: false,
            // where the SQL API is running, it will use a custom Host header to specify the username.
            endpoint: '${CARTODB_SQL_PRIVATE_URI}/api/v2/sql/job',
            // the template to use for adding the host header in the batch api requests
            hostHeaderTemplate: '{{=it.username}}.localhost.lan'
        },
        logger: {
            // If filename is given logs comming from analysis client  will be written
            // there, in append mode. Otherwise 'log_filename' is used. Otherwise stdout is used (default).
            // Log file will be re-opened on receiving the HUP signal
            filename: '/tmp/node-windshaft-analysis.log'
        },
        // Define max execution time in ms for analyses or tags
        // If analysis or tag are not found in redis this values will be used as default.
        limits: {
            moran: { timeout: 120000, maxNumberOfRows: 1e5 },
            cpu2x: { timeout: 60000 }
        }
    }
    ,millstone: {
        // Needs to be writable by server user
        cache_basedir: '/home/ubuntu/tile_assets/'
    }
    ,redis: {
        host: '${REDIS_HOST}',
        port: 6379,
        // Max number of connections in each pool.
        // Users will be put on a queue when the limit is hit.
        // Set to maxConnection to have no possible queues.
        // There are currently 2 pools involved in serving
        // windshaft-cartodb requests so multiply this number
        // by 2 to know how many possible connections will be
        // kept open by the server. The default is 50.
        max: 50,
        returnToHead: true, // defines the behaviour of the pool: false => queue, true => stack
        idleTimeoutMillis: 30000, // idle time before dropping connection
        reapIntervalMillis: 1000, // time between cleanups
        slowQueries: {
            log: true,
            elapsedThreshold: 200
        },
        slowPool: {
            log: true, // whether a slow acquire must be logged or not
            elapsedThreshold: 25 // the threshold to determine an slow acquire must be reported or not
        },
        emitter: {
            statusInterval: 5000 // time, in ms, between each status report is emitted from the pool, status is sent to statsd
        },
        unwatchOnRelease: false, // Send unwatch on release, see http://github.com/CartoDB/Windshaft-cartodb/issues/161
        noReadyCheck: true // Check no_ready_check at https://github.com/mranney/node_redis/tree/v0.12.1#overloading
    }
    // For more details about this options check https://nodejs.org/api/http.html#http_new_agent_options
    ,httpAgent: {
        keepAlive: true,
        keepAliveMsecs: 1000,
        maxSockets: 25,
        maxFreeSockets: 256
    }
    ,varnish: {
        host: 'localhost',
        port: 6082, // the por for the telnet interface where varnish is listening to
        http_port: 6081, // the port for the HTTP interface where varnish is listening to
        purge_enabled: false, // whether the purge/invalidation mechanism is enabled in varnish or not
        secret: 'xxx',
        ttl: 86400,
        fallbackTtl: 300,
        layergroupTtl: 86400 // the max-age for cache-control header in layergroup responses
    }
    ,fastly: {
        enabled: false,
        apiKey: 'wadus_api_key',
        serviceId: 'wadus_service_id'
    }
    ,useProfiler:false
    ,serverMetadata: {
      cdn_url: {
        http: undefined, // 'api.cartocdn.com',
        https: undefined, // 'cartocdn.global.ssl.fastly.net'
      }
    }
    ,health: {
      enabled: true,
      username: 'localhost',
      z: 0,
      x: 0,
      y: 0
    }
    ,disabled_file: 'pids/disabled'
    ,enabledFeatures: {
        onTileErrorStrategy: false,
        cdbQueryTablesFromPostgres: true,
        layerStats: false,
        rateLimitsEnabled: false,
        rateLimitsByEndpoint: {
            anonymous: false,
            static: false,
            static_named: false,
            dataview: false,
            dataview_search: false,
            analysis: false,
            analysis_catalog: false,
            tile: false,
            attributes: false,
            named_list: false,
            named_create: false,
            named_get: false,
            named: false,
            named_update: false,
            named_delete: false,
            named_tiles: false
        }
    }
};

module.exports = config;

EOT

echo "Run APP (env $APP_ENV)"
exec "$@"
