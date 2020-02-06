class TestMetricsReporter
  def self.report_event(name, attributes = {})

  end
end

describe Postgres::Vacuum::Jobs::MonitorJob do
  let(:job) { Postgres::Vacuum::Jobs::MonitorJob.new }

  describe "#perform" do
    let(:mock_connection) { double }

    before do
      allow(mock_connection).to receive(:execute).and_return([])
      ActiveRecord::Base.connection_handler.connection_pools.each do |pool|
        allow(pool).to receive(:with_connection).and_yield(mock_connection)
      end

      allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_reporter_class_name).and_return(TestMetricsReporter.name)
      allow(TestMetricsReporter).to receive(:report_event)
    end

    it "reports long running transaction events" do
      allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.long_running_transactions).and_return(
        [
          'xact_start' => 'test_xact_start',
          'seconds' => 'test_seconds',
          'application_name' => 'test_application_name',
          'query' => 'test_query',
          'state' => 'test_state'
        ]
      )

      job.perform

      expect(TestMetricsReporter).to have_received(:report_event).with(
        Postgres::Vacuum::Jobs::MonitorJob::LONG_TRANSACTIONS,
        database_name: 'postgres_vacuum_monitor_test',
        start_time: 'test_xact_start',
        running_time: 'test_seconds',
        application_name: 'test_application_name',
        most_recent_query: 'test_query',
        state: 'test_state'
      )
    end

    it "reports autovacuum lagging events" do
      allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.tables_eligible_vacuuming).and_return(
        [
          'relation' => 'test_relation',
          'table_size' => 512,
          'dead_tuples' => 3,
          'autovacuum_vacuum_tuples' => 1
        ]
      )

      job.perform

      expect(TestMetricsReporter).to have_received(:report_event).with(
        Postgres::Vacuum::Jobs::MonitorJob::AUTOVACUUM_LAGGING_EVENT,
        database_name: 'postgres_vacuum_monitor_test',
        table: 'test_relation',
        table_size: 512,
        dead_tuples: 3,
        tuples_over_limit: 2
      )
    end

    context "with multiple connection pools" do

      class SecondPool < ActiveRecord::Base
        # might be cleaner to put this in a method if that works.  constant is weird.
        establish_connection DB_CONFIG['test']
      end

      it "reports once for a single database." do
        expect(job.perform).to eq true
        expect(mock_connection).to have_received(:execute).twice
      end

      context "to different databases" do
        let(:name_change_db_config) { { name: 'my db' } }

        before do
          allow(SecondPool.connection_pool.spec).to receive(:config).and_return(name_change_db_config)
        end

        it "reports twice for two databases" do
          expect(job.perform).to eq true
          expect(mock_connection).to have_received(:execute).exactly(4)
        end
      end
    end
  end

  describe "#reporter_class" do
    it "throws an exception without configuration" do
      allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_reporter_class_name).and_return(nil)
      expect { job.reporter_class }.to raise_error(Postgres::Vacuum::Jobs::MonitorJob::ConfigurationError)
    end
  end
end
