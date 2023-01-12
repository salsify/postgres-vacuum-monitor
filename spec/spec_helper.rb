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

database_host = ENV.fetch('DB_HOST', 'localhost')
database_port = ENV.fetch('DB_PORT', 5432)
database_user = ENV.fetch('DB_USER', 'postgres')
database_password = ENV.fetch('DB_PASSWORD', 'password')
database_url = "postgres://#{database_user}:#{database_password}@#{database_host}:#{database_port}"
admin_database_name = "/#{ENV['ADMIN_DB_NAME']}" if ENV['ADMIN_DB_NAME'].present?

DATABASE_NAME = 'postgres_vacuum_monitor_test'

# rubocop:disable Rails/ApplicationRecord
class SecondPool < ActiveRecord::Base; end
SecondPool.establish_connection("#{database_url}/#{DATABASE_NAME}")
# rubocop:enable Rails/ApplicationRecord

def setup_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
  pg_conn.exec("CREATE DATABASE #{database_name}")

  pg_version = pg_conn.exec('SELECT version()')
  puts "Testing with Postgres version: #{pg_version.getvalue(0, 0)}"
  puts "Testing with ActiveRecord #{ActiveRecord::VERSION::STRING}"
end

def teardown_test_database(pg_conn, database_name)
  pg_conn.exec("DROP DATABASE IF EXISTS #{database_name}")
end

RSpec.configure do |config|
  config.before(:suite) do
    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      setup_test_database(connection, DATABASE_NAME)
    end

    ActiveRecord::Base.establish_connection("#{database_url}/#{DATABASE_NAME}")

    DatabaseCleaner.strategy = :transaction
  end

  config.after(:suite) do
    ActiveRecord::Base.connection_pool.disconnect!
    SecondPool.connection_pool.disconnect!

    PG::Connection.open("#{database_url}#{admin_database_name}") do |connection|
      teardown_test_database(connection, DATABASE_NAME)
    end
  end

  config.around do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
