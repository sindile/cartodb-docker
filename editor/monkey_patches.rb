require_relative '../../app/models/data_import'
require_relative '../../app/models/user/db_service.rb'
require_relative '../../app/models/user.rb'

class DataImport
  # Replace hardcoded domain
  def public_url
    return data_source unless uploaded_file

    "#{current_user.public_url}/#{uploaded_file[0]}"
  end
end

# Use newer version of dataservices
CartoDB::UserModule::DBService.send(:remove_const, 'CDB_DATASERVICES_CLIENT_VERSION')
CartoDB::UserModule::DBService.const_set('CDB_DATASERVICES_CLIENT_VERSION', '0.29.0'.freeze)

# Set custom Layers limit
if ENV.key?('DEFAULT_MAX_LAYERS')
  User.send(:remove_const, 'DEFAULT_MAX_LAYERS')
  User.const_set('DEFAULT_MAX_LAYERS', ENV['DEFAULT_MAX_LAYERS'])
end

# Set logger to STDOUT
Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
ActiveRecord::Base.logger = Rails.logger
