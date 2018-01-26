require 'coveralls'
Coveralls.wear!

require 'logger'
require 'database_cleaner'
require 'yaml'
require 'postgres/vacuum/monitor'

FileUtils.makedirs('log')

ActiveRecord::Base.logger = Logger.new('log/test.log')
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Migration.verbose = false
db_config = YAML.safe_load(File.read('spec/db/database.yml'))

RSpec.configure do |config|

  DATABASE_NAME = db_config['test']['database']

  config.before(:suite) do
    pg_version = `psql -t -c "select version()";`.strip
    puts "Testing with Postgres version: #{pg_version}"
    puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"

    ActiveRecord::Base.establish_connection(db_config['test'])

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
