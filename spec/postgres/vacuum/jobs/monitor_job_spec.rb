# frozen_string_literal: true

class TestMetricsReporter
  def self.report_event(name, attributes = {})

  end
end

describe Postgres::Vacuum::Jobs::MonitorJob do
  let(:job) { Postgres::Vacuum::Jobs::MonitorJob.new }

  describe "#perform" do
    before do
      allow(TestMetricsReporter).to receive(:report_event)
    end

    context "without a mocked connection" do
      before do
        allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_reporter_class_name)
                                                            .and_return(TestMetricsReporter.name)
      end

      it "executes all the queries" do
        expect(job.perform).to eq true

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::CONNECTION_STATE,
          database_name: instance_of(String),
          connection_count: instance_of(Integer),
          state: anything
        ).exactly(3).times # once for each state: nil, active, and idle

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::CONNECTION_IDLE_TIME,
          database_name: instance_of(String),
          max: instance_of(Integer),
          median: instance_of(Integer),
          percentile_90: instance_of(Integer)
        ).once
      end
    end

    context "with a mocked connection" do
      let(:mock_connection) { double }

      before do
        allow(mock_connection).to receive(:execute).and_return([])
        ActiveRecord::Base.connection_handler.connection_pools.each do |pool|
          allow(pool).to receive(:with_connection).and_yield(mock_connection)
        end

        allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_reporter_class_name)
                                                            .and_return(TestMetricsReporter.name)
      end

      it "reports long running transaction events" do
        allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.long_running_transactions)
                                                   .and_return(
                                                     [
                                                       'xact_start' => 'test_xact_start',
                                                       'seconds' => 60.00,
                                                       'application_name' => 'test_application_name',
                                                       'query' => 'test_query',
                                                         'state' => 'test_state',
                                                         'wait_event_type' => 'test_wait_event_type',
                                                         'backend_xid' => 'test_backend_xid',
                                                         'backend_xmin' => 'test_backend_xmin'
                                                     ]
                                                   )

        job.perform

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::LONG_TRANSACTIONS,
          database_name: 'postgres_vacuum_monitor_test',
          start_time: 'test_xact_start',
          running_time: 60,
          application_name: 'test_application_name',
          most_recent_query: 'test_query',
          state: 'test_state',
          wait_event_type: 'test_wait_event_type',
          transaction_id: 'test_backend_xid',
          min_transaction_id: 'test_backend_xmin'
        )
      end

      it "reports autovacuum lagging events" do
        allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.tables_eligible_vacuuming)
                                                   .and_return(
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

      it "reports blocked queries" do
        allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.blocked_queries).and_return(
          [
            'blocked_pid' => 2,
            'blocked_application' => 'foo',
            'blocked_statement' => 'SELECT 1 FROM products',
            'blocking_pid' => 3,
            'blocking_application' => 'bar',
            'current_statement_in_blocking_process' => 'SELECT 2 FROM products'
          ]
        )

        job.perform

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::BLOCKED_QUERIES,
          database_name: 'postgres_vacuum_monitor_test',
          blocked_application: 'foo',
          blocked_pid: 2,
          blocked_statement: 'SELECT 1 FROM products',
          blocking_pid: 3,
          blocking_application: 'bar',
          current_statement_in_blocking_process: 'SELECT 2 FROM products'
        )
      end

      it "reports connection state" do
        allow(mock_connection).to receive(:execute).with(Postgres::Vacuum::Monitor::Query.connection_state).and_return(
          ['connection_count' => 4, 'state' => 'idle']
        )

        job.perform

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::CONNECTION_STATE,
          database_name: 'postgres_vacuum_monitor_test',
          connection_count: 4,
          state: 'idle'
        )
      end

      it "reports connection idle time" do
        allow(mock_connection).to receive(:execute)
                                    .with(Postgres::Vacuum::Monitor::Query.connection_idle_time)
                                    .and_return(['max' => 3.1, 'median' => 222.22, 'percentile_90' => 9323.323])

        job.perform

        expect(TestMetricsReporter).to have_received(:report_event).with(
          Postgres::Vacuum::Jobs::MonitorJob::CONNECTION_IDLE_TIME,
          database_name: 'postgres_vacuum_monitor_test',
          max: 3,
          median: 222,
          percentile_90: 9323
        )
      end

      context "with multiple connection pools" do

        it "reports once for a single database." do
          expect(job.perform).to eq true
          expect(mock_connection).to have_received(:execute).exactly(5)
        end

        context "to different databases" do
          let(:name_change_db_config) { { name: 'my db' } }

          before do
            allow(SecondPool.connection_pool.db_config).to receive(:configuration_hash)
                                                             .and_return(name_change_db_config)
          end

          it "reports twice for two databases" do
            expect(job.perform).to eq true
            expect(mock_connection).to have_received(:execute).exactly(10)
          end
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

  describe "#max_attempts" do
    context "with default configuration" do
      it "makes 1 attempt" do
        expect(job.max_attempts).to eq(1)
      end
    end

    context "with custom configuration" do
      before do
        allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_max_attempts).and_return(3)
      end

      it "makes the configured number for attempts" do
        expect(job.max_attempts).to eq(3)
      end
    end
  end

  describe "#max_run_time" do
    context "with default configuration" do
      it "times out after 10 seconds" do
        expect(job.max_run_time).to eq(10.seconds)
      end
    end

    context "with custom configuration" do
      before do
        allow(Postgres::Vacuum::Monitor.configuration).to receive(:monitor_max_run_time_seconds).and_return(60)
      end

      it "times out after the configured number of seconds" do
        expect(job.max_run_time).to eq(60.seconds)
      end
    end
  end
end
