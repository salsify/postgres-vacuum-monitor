describe Postgres::Vacuum::Jobs::MonitorJob do
  let(:job) { Postgres::Vacuum::Jobs::MonitorJob.new }

  describe "#perform" do
    it "finishes without exceptions." do
      expect(job.perform).to eq true
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
