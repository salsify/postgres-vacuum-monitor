describe Postgres::Vacuum::Monitor::Query do

  describe ".long_query" do
    it "respects the time window" do
      expect(Postgres::Vacuum::Monitor::Query.long_running_queries).to include "seconds > #{Postgres::Vacuum::Monitor::Query::TIME_LIMIT}"
    end

    it "respects the states" do
      expect(Postgres::Vacuum::Monitor::Query.long_running_queries).to include "WHERE state IN (#{Postgres::Vacuum::Monitor::Query::STATES.join(', ')})"
    end
  end
end
