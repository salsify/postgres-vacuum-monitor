require 'active_record'
require 'postgres/vacuum/configuration'
require 'postgres/vacuum/monitor/version'
require 'postgres/vacuum/monitor/query'
require 'postgres/vacuum/jobs/monitor_job'

module Postgres
  module Vacuum
    module Monitor
      class << self
        attr_accessor :config
      end

      def self.configuration
        @config ||= Configuration.new
      end

      def self.reset
        @config = Configuration.new
      end

      def self.configure
        yield(configuration)
      end
    end
  end
end
