module Postgres
  module Vacuum
    module Monitor
      module Query
        extend self

        STATES = ["'idle in transaction'", "'active'"].freeze
        THRESHOLD_SETTING = "'autovacuum_vacuum_threshold'".freeze
        SCALE_FACTOR_SETTING = "'autovacuum_vacuum_scale_factor'".freeze
        MAX_AGE_SETTING = "'autovacuum_freeze_max_age'".freeze
        PG_CATALOG = "'pg_catalog'".freeze

        def long_running_transactions
          <<-SQL
            SELECT *
            FROM (
              SELECT
                pid,
                xact_start,
                EXTRACT(EPOCH FROM (now() - xact_start)) AS seconds,
                application_name,
                query,
                state,
                backend_xid,
                backend_xmin,
                wait_event_type
              FROM pg_stat_activity
              WHERE state IN (#{STATES.join(', ')})
              ORDER BY seconds DESC
            ) AS long_queries
            WHERE seconds > #{Postgres::Vacuum::Monitor.configuration.long_running_transaction_threshold_seconds};
          SQL
        end

        def tables_eligible_vacuuming
          # The query was taken from http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html
          <<-SQL
            WITH vbt AS (
            SELECT setting AS autovacuum_vacuum_threshold FROM pg_settings WHERE name = #{THRESHOLD_SETTING}) , vsf AS (
              SELECT setting AS autovacuum_vacuum_scale_factor FROM pg_settings WHERE name = #{SCALE_FACTOR_SETTING}) , fma AS (
                SELECT setting AS autovacuum_freeze_max_age FROM pg_settings WHERE name = #{MAX_AGE_SETTING}) , sto AS (
                  SELECT opt_oid, split_part(setting, '=', 1) AS param, split_part(setting, '=', 2) AS value FROM (
                    SELECT oid opt_oid, unnest(reloptions) setting FROM pg_class
                  ) opt
                )
                  SELECT '"'||ns.nspname||'"."'||c.relname||'"' AS relation,
                          pg_size_pretty(pg_table_size(c.oid)) AS table_size,
                          age(relfrozenxid) AS xid_age,
                          coalesce(cfma.value::float, autovacuum_freeze_max_age::float) autovacuum_freeze_max_age,
                          (
                            coalesce(cvbt.value::float, autovacuum_vacuum_threshold::float) +
                            coalesce(cvsf.value::float,autovacuum_vacuum_scale_factor::float) * pg_table_size(c.oid)
                          ) AS autovacuum_vacuum_tuples,
                          n_dead_tup AS dead_tuples
                  FROM pg_class c
                  JOIN pg_namespace ns ON ns.oid = c.relnamespace
                  JOIN pg_stat_all_tables stat ON stat.relid = c.oid
                  JOIN vbt ON (1=1) JOIN vsf ON (1=1)
                  JOIN fma ON (1=1)
                  LEFT JOIN sto cvbt ON cvbt.param = #{THRESHOLD_SETTING} AND c.oid = cvbt.opt_oid
                  LEFT JOIN sto cvsf ON cvsf.param = #{SCALE_FACTOR_SETTING} AND c.oid = cvsf.opt_oid
                  LEFT JOIN sto cfma ON cfma.param = #{MAX_AGE_SETTING} AND c.oid = cfma.opt_oid
                  WHERE c.relkind = 'r'
                    AND nspname <> #{PG_CATALOG}
                    AND ( age(relfrozenxid) >= coalesce(cfma.value::float, autovacuum_freeze_max_age::float)
                    OR coalesce(cvbt.value::float, autovacuum_vacuum_threshold::float) + coalesce(cvsf.value::float,autovacuum_vacuum_scale_factor::float) * pg_table_size(c.oid) <= n_dead_tup)
            ORDER BY  age(relfrozenxid) DESC LIMIT 50;
          SQL
        end

        def blocked_queries
          # The query was taken from https://wiki.postgresql.org/wiki/Lock_Monitoring
          <<-SQL
            SELECT blocked_locks.pid AS blocked_pid, blocked_activity.usename AS blocked_user, blocking_locks.pid AS blocking_pid, 
              blocking_activity.usename AS blocking_user, blocked_activity.query AS blocked_statement,blocking_activity.query AS current_statement_in_blocking_process 
            FROM pg_catalog.pg_locks blocked_locks 
            JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid 
            JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype AND 
              blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE AND 
              blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation AND 
              blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page AND 
              blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple AND 
              blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid AND 
              blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid AND 
              blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid AND 
              blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid AND 
              blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid AND 
              blocking_locks.pid != blocked_locks.pid 
            JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid 
            WHERE NOT blocked_locks.GRANTED;
          SQL
        end
      end
    end
  end
end
