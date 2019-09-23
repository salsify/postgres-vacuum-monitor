module Postgres
  module Vacuum
    module Jobs
      class MonitorJob

        AUTOVACUUM_QUERY_EVENT = 'AutoVacuumLagging'.freeze
        LONG_QUERIES = 'LongQueries'.freeze

        def perform(*)
          with_each_db_name_and_connection do |name, connection|
            connection.execute(Postgres::Vacuum::Monitor::Query.long_running_queries).each do |row|
              reporter_class.report_event(
                LONG_QUERIES,
                database_name: name,
                start_time: row['xact_start'],
                running_time: row['seconds'],
                application_name: row['application_name'],
                query: row['query']
              )
            end

            connection.execute(Postgres::Vacuum::Monitor::Query.tables_eligible_vacuuming).each do |row|
              reporter_class.report_event(
                AUTOVACUUM_QUERY_EVENT,
                database_name: name,
                table: row['relation'],
                table_size: row['table_size'],
                dead_tuples: row['dead_tuples'].to_i,
                tuples_over_limit: row['dead_tuples'].to_i - row['autovacuum_vacuum_tuples'].to_i
              )
            end
          end

          true
        end

        def reporter_class
          return @reporter_class_name if @reporter_class_name

          @reporter_class_name = Postgres::Vacuum::Monitor.configuration.monitor_reporter_class_name&.safe_constantize
          raise ConfigurationError.new('Missing or invalid report class name. Check your configuration') if @reporter_class_name.nil?

          @reporter_class_name
        end

        def with_each_db_name_and_connection
          databases = Set.new
          ActiveRecord::Base.connection_handler.connection_pools.map do |connection_pool|
            db_name = connection_pool.spec.config[:database]
            # activerecord allocates a connection pool per call to establish_connection
            # multiple pools might interact with the same database so we use the
            # database name to dedup
            connection_pool.with_connection { |conn| yield(db_name, conn) } if databases.add?(db_name)
          end
        end

        ConfigurationError = Class.new(StandardError)
      end
    end
  end
end
