# frozen_string_literal: true

describe Postgres::Vacuum::Monitor::Query do

  describe ".long_query" do
    it "respects the time window" do
      query = "seconds > #{Postgres::Vacuum::Monitor.configuration.long_running_transaction_threshold_seconds}"
      expect(Postgres::Vacuum::Monitor::Query.long_running_transactions).to include(query)
    end

    it "respects the states" do
      query = "WHERE state IN (#{Postgres::Vacuum::Monitor::Query::STATES.join(', ')})"
      expect(Postgres::Vacuum::Monitor::Query.long_running_transactions).to include(query)
    end

    it "generates a runnable query" do
      ActiveRecord::Base.connection.execute(Postgres::Vacuum::Monitor::Query.long_running_transactions)
    end
  end

  describe ".tables_eligible_vacuuming" do
    it "generates a runnable query" do
      ActiveRecord::Base.connection.execute(Postgres::Vacuum::Monitor::Query.tables_eligible_vacuuming)
    end
  end
end
