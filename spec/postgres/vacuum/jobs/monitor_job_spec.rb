describe Postgres::Vacuum::Jobs::MonitorJob do
  let(:job) { Postgres::Vacuum::Jobs::MonitorJob.new }

  describe "#perform" do

    let(:mock_connection) { double }
    before do
      allow(mock_connection).to receive(:execute).and_return([])
      ActiveRecord::Base.connection_handler.connection_pools.each do |pool|
        allow(pool).to receive(:with_connection).and_yield(mock_connection)
      end
    end

    it "finishes without exceptions." do
      expect(job.perform).to eq true
    end

    it "reports an event per query." do
      expect(job.perform).to eq true
      expect(mock_connection).to have_received(:execute).twice
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
      expect { job.reporter_class }.to raise_error(Postgres::Vacuum::Jobs::MonitorJob::ConfigurationError)
    end

    context "with a configuration set" do

      class TestReporter
      end

      before do
        Postgres::Vacuum::Monitor.configure do |config|
          config.monitor_reporter_class_name = 'TestReporter'
        end
      end

      after do
        Postgres::Vacuum::Monitor.configure do |config|
          config.monitor_reporter_class_name = nil
        end
      end

      specify { expect(job.reporter_class).to eq TestReporter }
    end
  end
end
