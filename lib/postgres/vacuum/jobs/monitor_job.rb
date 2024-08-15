# frozen_string_literal: true

module Postgres
  module Vacuum
    module Jobs
      class MonitorJob

        AUTOVACUUM_LAGGING_EVENT = 'AutoVacuumLagging'
        LONG_TRANSACTIONS = 'LongTransactions'
        BLOCKED_QUERIES = 'BlockedQueries'
        CONNECTION_STATE = 'ConnectionState'
        CONNECTION_IDLE_TIME = 'ConnectionIdleTime'

        def max_run_time
          Postgres::Vacuum::Monitor.configuration.monitor_max_run_time_seconds.seconds
        end

        def max_attempts
          Postgres::Vacuum::Monitor.configuration.monitor_max_attempts
        end

        def perform(*)
          with_each_db_name_and_connection do |name, connection|
            connection.execute(Postgres::Vacuum::Monitor::Query.long_running_transactions).each do |row|
              reporter_class.report_event(
                LONG_TRANSACTIONS,
                database_name: name,
                start_time: row['xact_start'],
                running_time: row['seconds'].to_i,
                application_name: row['application_name'],
                most_recent_query: row['query'],
                state: row['state'],
                wait_event_type: row['wait_event_type'],
                transaction_id: row['backend_xid'],
                min_transaction_id: row['backend_xmin']
              )
            end

            connection.execute(Postgres::Vacuum::Monitor::Query.tables_eligible_vacuuming).each do |row|
              reporter_class.report_event(
                AUTOVACUUM_LAGGING_EVENT,
                database_name: name,
                table: row['relation'],
                table_size: row['table_size'],
                dead_tuples: row['dead_tuples'].to_i,
                tuples_over_limit: row['dead_tuples'].to_i - row['autovacuum_vacuum_tuples'].to_i
              )
            end

            connection.execute(Postgres::Vacuum::Monitor::Query.blocked_queries).each do |row|
              reporter_class.report_event(
                BLOCKED_QUERIES,
                database_name: name,
                blocked_pid: row['blocked_pid'],
                blocked_application: row['blocked_application'],
                blocked_statement: row['blocked_statement'],
                blocking_pid: row['blocking_pid'],
                blocking_application: row['blocking_application'],
                current_statement_in_blocking_process: row['current_statement_in_blocking_process']
              )
            end

            connection.execute(Postgres::Vacuum::Monitor::Query.connection_state).each do |row|
              reporter_class.report_event(
                CONNECTION_STATE,
                database_name: name,
                state: row['state'],
                connection_count: row['connection_count']
              )
            end

            connection.execute(Postgres::Vacuum::Monitor::Query.connection_idle_time).each do |row|
              reporter_class.report_event(
                CONNECTION_IDLE_TIME,
                database_name: name,
                max: row['max'].to_i,
                median: row['median'].to_i,
                percentile_90: row['percentile_90'].to_i
              )
            end
          end

          true
        end

        def reporter_class
          return @reporter_class_name if @reporter_class_name

          @reporter_class_name = Postgres::Vacuum::Monitor.configuration.monitor_reporter_class_name&.safe_constantize
          if @reporter_class_name.nil?
            raise ConfigurationError.new('Missing or invalid report class name. Check your configuration')
          end

          @reporter_class_name
        end

        def with_each_db_name_and_connection
          databases = Set.new
          ActiveRecord::Base.connection_handler.connection_pools.map do |connection_pool|
            db_name = connection_pool.db_config.configuration_hash[:database]
            next unless databases.add?(db_name)

            # ActiveRecord allocates a connection pool per call to `.establish_connection`
            # As a result, multiple pools might interact with the same database, so we use
            # the database name to dedupe.
            connection_pool.with_connection do |connection|
              original_timeout = statement_timeout(connection)
              set_statement_timeout(connection, "#{configured_timeout_seconds}s")

              yield(db_name, connection)
            ensure
              set_statement_timeout(connection, original_timeout)
            end

          # We want to avoid hanging onto a bad connection that would cause all future
          # jobs to fail, so we eagerly clear the pool.
          rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionTimeoutError
            connection_pool.disconnect!
            raise
          end
        end

        def statement_timeout(connection)
          result = connection.execute('SHOW statement_timeout').first
          result['statement_timeout'] if result.present?
        end

        def set_statement_timeout(connection, timeout)
          query = ActiveRecord::Base.sanitize_sql(['SET statement_timeout = ?', timeout])
          connection.execute(query)
        end

        def configured_timeout_seconds
          Postgres::Vacuum::Monitor.configuration.monitor_statement_timeout_seconds
        end

        ConfigurationError = Class.new(StandardError)
      end
    end
  end
end
