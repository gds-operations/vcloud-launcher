require 'spec_helper'

class CommandRun
  attr_accessor :stdout, :stderr, :exitstatus

  def initialize(args)
    out = StringIO.new
    err = StringIO.new

    $stdout = out
    $stderr = err

    begin
      Vcloud::Launcher::Cli.new(args).run
      @exitstatus = 0
    rescue SystemExit => e
      # Capture exit(n) value.
      @exitstatus = e.status
    end

    @stdout = out.string.strip
    @stderr = err.string.strip

    $stdout = STDOUT
    $stderr = STDERR
  end
end

describe Vcloud::Launcher::Cli do
  subject { CommandRun.new(args) }

  let(:mock_launch) {
    double(:launch, :run => true)
  }
  let(:config_file) { 'config.yaml' }

  describe "under normal usage" do
    shared_examples "a good CLI command" do
      it "passes the right CLI options and exits normally" do
        expect(Vcloud::Launcher::Launch).to receive(:new).
          with(config_file, cli_options).and_return(mock_launch)

        expect(subject.exitstatus).to eq(0)
      end
    end

    context "when given a single config file" do
      let(:args) { [ config_file ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => false,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked not to power VMs on" do
      let(:args) { [ config_file, "--dont-power-on" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => true,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => false,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to continue on error" do
      let(:args) { [ config_file, "--continue-on-error" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => true,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => false,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to be quiet" do
      let(:args) { [ config_file, "--quiet" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => true,
          "post-launch-cmd"   => false,
          "verbose"           => false,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to be verbose" do
      let(:args) { [ config_file, "--verbose" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => true,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to be verbose and continue on errors" do
      let(:args) { [ config_file, "--continue-on-error", "--verbose" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => true,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => true,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to run a command on launch" do
      let(:args) { [ config_file, "--post-launch-cmd", "GIRAFFE" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => 'GIRAFFE',
          "verbose"           => false,
        }
      }

      it_behaves_like "a good CLI command"
    end

    context "when asked to run an invalid command on launch" do
      let(:args) { [ config_file, "--post-launch-cmd", "GIRAFFE LION" ] }
      let(:cli_options) {
        {
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => 'GIRAFFE LION',
          "verbose"           => false,
        }
      }
      it "exits with a non-zero status" do
        expect(subject.exitstatus).not_to eq(0)
      end
    end

    context "when asked to display version" do
      let(:args) { %w{--version} }

      it "does not call Launch" do
        expect(Vcloud::Launcher::Launch).not_to receive(:new)
      end

      it "prints version and exits normally" do
        expect(subject.stdout).to eq(Vcloud::Launcher::VERSION)
        expect(subject.exitstatus).to eq(0)
      end
    end

    context "when asked to display help" do
      let(:args) { %w{--help} }

      it "does not call Launch" do
        expect(Vcloud::Launcher::Launch).not_to receive(:new)
      end

      it "prints usage and exits normally" do
        expect(subject.stderr).to match(/\AUsage: \S+ \[options\] config_file\n/)
        expect(subject.exitstatus).to eq(0)
      end
    end
  end

  describe '.run' do
    let(:mock_launch) { double(:launch, :run => true) }

    subject { Vcloud::Launcher::Cli.new([ config_file ]) }

    it 'calls Vcloud::Launcher::Launch.run' do
      allow( Vcloud::Launcher::Launch).to receive(:new).and_return(mock_launch)

      expect(mock_launch).to receive(:run)

      begin
        subject.run
      rescue SystemExit => e
        e.exitstatus
      end
    end
  end

  describe "incorrect usage" do
    shared_examples "print usage and exit abnormally" do |error|
      it "does not call Launch" do
        expect(Vcloud::Launcher::Launch).not_to receive(:new)
      end

      it "prints error message and usage" do
        expect(subject.stderr).to match(/\A\S+: #{error}\nUsage: \S+/)
      end

      it "exits abnormally for incorrect usage" do
        expect(subject.exitstatus).to eq(2)
      end
    end

    context "when run without any arguments" do
      let(:args) { %w{} }

      it_behaves_like "print usage and exit abnormally", "must supply config_file"
    end

    context "when given multiple config files" do
      let(:args) { %w{one.yaml two.yaml} }

      it_behaves_like "print usage and exit abnormally", "must supply config_file"
    end

    context "when given an unrecognised argument" do
      let(:args) { %w{--this-is-garbage} }

      it_behaves_like "print usage and exit abnormally", "invalid option: --this-is-garbage"
    end
  end

  describe "error handling" do
    context "when underlying code raises an exception" do
      let(:args) { %w{test.yaml} }

      it "should print error without backtrace and exit abnormally" do
        expect(Vcloud::Launcher::Launch).to receive(:new).
          and_raise("something went horribly wrong")
        expect(subject.stderr).to eq("something went horribly wrong")
        expect(subject.exitstatus).to eq(1)
      end
    end

    context "when passed an non-existent configuration file" do
      let(:args) { %w{non-existent.yaml} }

      it "raises a descriptive error" do
        expect(subject.stderr).to match("No such file or directory(?: @ rb_sysopen)? - non-existent.yaml")
        expect(subject.exitstatus).to eq(1)
      end
    end
  end
end
