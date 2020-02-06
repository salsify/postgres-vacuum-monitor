describe Postgres::Vacuum::Monitor::Query do

  describe ".long_query" do
    it "respects the time window" do
      expect(Postgres::Vacuum::Monitor::Query.long_running_transactions).to include "seconds > #{Postgres::Vacuum::Monitor::Query::TIME_LIMIT}"
    end

    it "respects the states" do
      expect(Postgres::Vacuum::Monitor::Query.long_running_transactions).to include "WHERE state IN (#{Postgres::Vacuum::Monitor::Query::STATES.join(', ')})"
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
