module Postgres
  module Vacuum
    class Configuration
      attr_accessor :monitor_reporter_class_name

      def initialize
        @monitor_reporter_class_name = nil
      end
    end
  end
end
