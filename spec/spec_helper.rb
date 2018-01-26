require 'logger'
require 'database_cleaner'
require 'yaml'
require 'postgres/vacuum/monitor'

FileUtils.makedirs('log')

ActiveRecord::Base.logger = Logger.new('log/test.log')
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Migration.verbose = false

db_config = YAML.safe_load(File.read('spec/db/database.yml'))
ActiveRecord::Base.establish_connection(db_config['test'])
require 'db/schema'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
