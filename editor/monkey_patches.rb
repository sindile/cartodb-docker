require_relative '../../app/models/data_import'

class DataImport
  # Replace hardcoded domain
  def public_url
    return data_source unless uploaded_file

    "#{current_user.public_url}/#{uploaded_file[0]}"
  end
end

# Set logger to STDOUT
Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
ActiveRecord::Base.logger = Rails.logger
