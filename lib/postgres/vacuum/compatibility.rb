module Postgres
  module Vacuum
    class Compatibility
      ACTIVE_RECORD_VERSION = ::Gem::Version.new(::ActiveRecord::VERSION::STRING).release
      PRE_RAILS_6_1 = ACTIVE_RECORD_VERSION < ::Gem::Version.new('6.1.0')

      def self.pre_rails_6_1?
        PRE_RAILS_6_1
      end

    end
  end
end
