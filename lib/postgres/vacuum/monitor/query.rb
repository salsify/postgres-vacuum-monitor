module Postgres
  module Vacuum
    module Monitor
      module Query
        extend self

        STATES = ["'idle in transaction'", "'active'"].freeze
        TIME_LIMIT = 3600
        THRESHOLD_SETTING = "'autovacuum_vacuum_threshold'".freeze
        SCALE_FACTOR_SETTING = "'autovacuum_vacuum_scale_factor'".freeze
        MAX_AGE_SETTING = "'autovacuum_freeze_max_age'".freeze
        PG_CATALOG = "'pg_catalog'".freeze

        def long_running_queries
          <<-SQL
            SELECT *
            FROM (
              SELECT
                pid,
                xact_start,
                EXTRACT(EPOCH FROM (now() - xact_start)) AS seconds,
                application_name,
                query
              FROM pg_stat_activity
              WHERE state IN (#{STATES.join(', ')})
              ORDER BY seconds DESC
            ) AS long_queries
            WHERE seconds > #{TIME_LIMIT};
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
      end
    end
  end
end
