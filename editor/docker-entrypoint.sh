#!/usr/bin/env sh

set -ex

echo "# Writing configuration file #"
echo "Setup config/app_config.yml"
ruby <<-EOF
  require 'yaml'
  require 'pathname'
  require 'uri'
  require 'securerandom'

  APP_ROOT = Pathname.new(ENV.fetch('APP_ROOT', '/app'))
  CARTODB_DOMAIN = ENV.fetch('CARTODB_DOMAIN', 'cartodb')

  configs = YAML.load_file(APP_ROOT.join('config/app_config.yml.sample'))
  config  = configs['production']
  config['cdn_url'] = nil
  config['http_port'] = ENV.fetch('CARTODB_HTTP_PORT', 3000)
  config['https_port'] = ENV.fetch('CARTODB_HTTPS_PORT', 443)
  config['secret_token'] = ENV.fetch('CARTODB_SECRET_TOKEN', SecureRandom.hex(32))
  config['secret_key_base'] = ENV.fetch('CARTODB_SECRET_KEY_BASE', SecureRandom.hex(64))
  config['password_secret'] = ENV.fetch('CARTODB_PASSWORD_SECRET', SecureRandom.hex(64))
  config['account_host'] = ENV.fetch('CARTODB_ACCOUNT_HOST', CARTODB_DOMAIN)
  config['cartodb_com_hosted'] = false
  config['vizjson_cache_domains'] = Array(ENV.fetch('CARTODB_SESSION_DOMAIN', CARTODB_DOMAIN))
  config['subdomainless_urls'] = [true, 'yes', 'true', '1'].include?(ENV.fetch('CARTODB_SUBDOMAINLESS_URLS', 'false'))
  config['aggregation_tables'] = {
    'host' => ENV.fetch('POSTGRES_HOST', 'db'),
    'port' => ENV.fetch('POSTGRES_PORT', '5432'),
    'dbname' => ENV.fetch('POSTGRES_DB', 'cartodb'),
    'username' => ENV.fetch('POSTGRES_USER', 'cartodb'),
    'password' => ENV.fetch('POSTGRES_PASSWORD', 'cartodb'),
    'tables' => {
      'admin0' => 'ne_admin0_v3',
      'admin1' => 'global_province_polygons'
    }
  }
  config['common_data']['base_url'] = '//#{CARTODB_DOMAIN}/'
  config['error_track']['url'] = "#{CARTODB_DOMAIN}/api/v1/sql"
  config['layer_opts']['data']['options']['tiler_domain'] = ENV.fetch('CARTODB_TILER_DOMAIN', CARTODB_DOMAIN)
  config['layer_opts']['data']['options']['sql_domain'] = ENV.fetch('CARTODB_SQL_DOMAIN', CARTODB_DOMAIN)
  config['cartodb_central_domain_name'] = ENV.fetch('CARTODB_CENTRAL_DOMAN', CARTODB_DOMAIN)
  config['redis']['host'] = ENV.fetch('REDIS_HOST', 'redis')
  config['session_domain'] = ENV.fetch('CARTODB_SESSION_DOMAIN', CARTODB_DOMAIN)
  config['app_assets']['asset_host'] = ENV.fetch('CARTODB_ASSETS_HOST', "//#{CARTODB_DOMAIN}")

  tiler_internal_uri = URI(ENV['CARTODB_TILER_INTERNAL_URI'] || "http://#{CARTODB_DOMAIN}:8081")
  config['tiler']['internal']['domain'] = tiler_internal_uri.host
  config['tiler']['internal']['host'] = tiler_internal_uri.host
  config['tiler']['internal']['protocol'] = tiler_internal_uri.scheme
  config['tiler']['internal']['port'] = tiler_internal_uri.port

  tiler_private_uri = URI(ENV['CARTODB_TILER_PRIVATE_URI'] || "http://#{CARTODB_DOMAIN}:8081")
  config['tiler']['private']['domain'] = tiler_private_uri.host
  config['tiler']['private']['host'] = tiler_private_uri.host
  config['tiler']['private']['protocol'] = tiler_private_uri.scheme
  config['tiler']['private']['port'] = tiler_private_uri.port

  tiler_public_uri = URI(ENV['CARTODB_TILER_PUBLIC_URI'] || "http://#{CARTODB_DOMAIN}:8081")
  config['tiler']['public']['domain'] = tiler_public_uri.host
  config['tiler']['public']['host'] = tiler_public_uri.host
  config['tiler']['public']['protocol'] = tiler_public_uri.scheme
  config['tiler']['public']['port'] = tiler_public_uri.port

  invalidation = ENV['CARTODB_INVALIDATION_SERVICE_URI']
  if invalidation
    invalidation_uri = URI(invalidation)
    config['invalidation_service']['host'] = invalidation_uri.host
    config['invalidation_service']['port'] = invalidation_uri.port
  else
    config.delete 'invalidation_service'
  end

  sql_api = URI(ENV.fetch('CARTODB_SQL_API_PRIVATE_URI', "http://#{CARTODB_DOMAIN}/api/v1/map"))
  config['sql_api']['private']['protocol'] = sql_api.scheme
  config['sql_api']['private']['domain'] = sql_api.host
  config['sql_api']['private']['endpoint'] = sql_api.path
  config['sql_api']['private']['port'] = sql_api.port

  sql_api = URI(ENV.fetch('CARTODB_SQL_API_PUBLIC_URI', "http://#{CARTODB_DOMAIN}/api/v2/sql"))
  config['sql_api']['public']['protocol'] = sql_api.scheme
  config['sql_api']['public']['domain'] = sql_api.host
  config['sql_api']['public']['endpoint'] = sql_api.path
  config['sql_api']['public']['port'] = sql_api.port

  uploads_path = ENV['RAILS_PUBLIC_UPLOADS_PATH']
  if uploads_path
    config['exporter']['uploads_path'] = uploads_path if config['exporter']
    config['importer']['uploads_path'] = uploads_path if config['importer']
    config['user_migrator']['uploads_path'] = uploads_path if config['user_migrator']
  end

  config['metrics']['hubspot']['token'] = ENV['HUBSPOT_TOKEN']
  config['metrics']['hubspot']['events_host'] = ENV.fetch('HUBSPOT_URL', 'http://track.hubspot.com')

  config['geocoder']['api']['host'] = ENV.fetch('POSTGRES_HOST', 'db')
  config['geocoder']['api']['user'] = ENV.fetch('POSTGRES_USER', 'db')

  config['enabled'] = {
    'geocoder_internal' => true,
    'hires_geocoder'    => false,
    'isolines'          => false,
    'routing'           => false,
    'data_observatory'  => true
  }

  File.open(APP_ROOT.join('config/app_config.yml'), 'w') { |f| f.write({'production' => config}.to_yaml) }
EOF

echo "Setup config/database.yml"
ruby <<-EOF
  require 'yaml'
  require 'pathname'

  APP_ROOT = Pathname.new(ENV.fetch('APP_ROOT', '/app'))
  configs = YAML.load_file(APP_ROOT.join('config/database.yml.sample'))
  config  = configs['production']
  config['host'] = ENV.fetch('POSTGRES_HOST', 'db')
  config['port'] = ENV.fetch('POSTGRES_PORT', '5432')
  config['username'] = ENV.fetch('POSTGRES_USER', 'cartodb')
  config['password'] = ENV.fetch('POSTGRES_PASSWORD', 'cartodb')
  config['database'] = ENV.fetch('POSTGRES_DB', 'cartodb')

  File.open(APP_ROOT.join('config/database.yml'), 'w') { |f| f.write(configs.to_yaml) }
EOF

echo 'Wait for database'
while ! nc -z $POSTGRES_HOST 5432; do sleep 1; done

echo "Run APP"
exec "$@"
