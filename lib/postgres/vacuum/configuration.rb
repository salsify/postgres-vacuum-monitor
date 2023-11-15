# frozen_string_literal: true

module Postgres
  module Vacuum
    class Configuration
      DEFAULT_LONG_RUNNING_TRANSACTION_THRESHOLD_SECONDS = 5 * 60
      DEFAULT_MONITOR_MAX_RUN_TIME_SECONDS = 10
      DEFAULT_MONITOR_MAX_ATTEMPTS = 1

      attr_accessor :monitor_reporter_class_name,
                    :long_running_transaction_threshold_seconds,
                    :monitor_max_run_time_seconds,
                    :monitor_max_attempts

      def initialize
        self.monitor_reporter_class_name = nil
        self.long_running_transaction_threshold_seconds = DEFAULT_LONG_RUNNING_TRANSACTION_THRESHOLD_SECONDS
        self.monitor_max_run_time_seconds = DEFAULT_MONITOR_MAX_RUN_TIME_SECONDS
        self.monitor_max_attempts = DEFAULT_MONITOR_MAX_ATTEMPTS
      end
    end
  end
end
