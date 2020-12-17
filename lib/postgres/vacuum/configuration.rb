# frozen_string_literal: true

module Postgres
  module Vacuum
    class Configuration
      DEFAULT_LONG_RUNNING_TRANSACTION_THRESHOLD_SECONDS = 5 * 60
      attr_accessor :monitor_reporter_class_name, :long_running_transaction_threshold_seconds

      def initialize
        self.monitor_reporter_class_name = nil
        self.long_running_transaction_threshold_seconds = DEFAULT_LONG_RUNNING_TRANSACTION_THRESHOLD_SECONDS
      end
    end
  end
end
