# frozen_string_literal: true

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
db_config = YAML.safe_load(ERB.new(File.read('spec/db/database.yml')).result)
DB_CONFIG = db_config

# rubocop:disable Rails/ApplicationRecord
class SecondPool < ActiveRecord::Base
  # might be cleaner to put this in a method if that works.  constant is weird.
  establish_connection DB_CONFIG['test']
end
# rubocop:enable Rails/ApplicationRecord

RSpec.configure do |config|

  config.before(:suite) do
    test_config = db_config['test']
    url = "postgresql://#{test_config['username']}@#{test_config['host']}/#{test_config['database']}"
    pg_version = `psql -d #{url} -t -c "select version()";`.strip

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
