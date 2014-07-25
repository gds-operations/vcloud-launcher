require 'spec_helper'

describe Vcloud::Launcher::Launch do
  let(:good_vapp_one) do
    {
      name: "successful app 1",
      vdc_name: "Test Vdc",
      catalog_name: "default",
      vapp_template_name: "ubuntu-precise"
    }
  end
  let(:good_vapp_two) do
    {
      name: "successful app 2",
      vdc_name: "Test Vdc",
      catalog_name: "default",
      vapp_template_name: "ubuntu-precise"
    }
  end
  let(:bad_vapp_one) do
    {
      name: "fake failing app",
      vdc_name: "wrong vdc",
      catalog_name: "default",
      vapp_template_name: "ubuntu-precise"
    }
  end

  let(:config) do
    { vapps: [ good_vapp_one, bad_vapp_one, good_vapp_two ] }
  end

  let(:config_file) { 'foo.yml' }
  let(:config_loader) { double(:config_loader) }

  before do
    allow(Vcloud::Core::ConfigLoader).to receive(:new).and_return(config_loader)
    allow(config_loader).to receive(:load_config).and_return(config)
  end

  describe '#new' do
    subject { Vcloud::Launcher::Launch }

    context 'with minimally correct configuration' do
      it 'does not raise an error' do
        expect{ subject.new(config_file) }.not_to raise_error
      end

      it 'loads configuration' do
        config_loader.should_receive(:load_config).and_return(config)
        subject.new(config_file)
      end

      it 'validates the configuration' do
        subject.any_instance.should_receive(:validate_config)
        subject.new(config_file)
      end
    end

    context 'without a configuration file' do
      it 'raises an error' do
        expect { subject.new }.to raise_error(ArgumentError)
      end
    end
  end

  context "#run" do
    subject { Vcloud::Launcher::Launch.new(config_file, cli_options) }

    before do
      allow(Vcloud::Launcher::VappOrchestrator).to receive(:provision).
        with(good_vapp_one).and_return(double(:vapp, power_on: true))
    end

    context "default behaviour on failure" do
      let(:cli_options) { {} }

      it "should stop" do
        allow(Vcloud::Launcher::VappOrchestrator).to receive(:provision).
          with(bad_vapp_one).and_raise(RuntimeError.new('failed to find vdc'))

        expect(Vcloud::Launcher::VappOrchestrator).not_to receive(:provision).with(good_vapp_two)

        subject.run
      end
    end

    context "with continue_on_error set" do
      let(:cli_options) { {continue_on_error: true} }

      it "should continue" do
        allow(Vcloud::Launcher::VappOrchestrator).to receive(:provision).
          with(bad_vapp_one).and_raise(RuntimeError.new('failed to find vdc'))

        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(good_vapp_two).and_return(double(:vapp, :power_on => true))

        subject.run
      end
    end
  end

  context "#set_logging_level" do
    subject { Vcloud::Launcher::Launch.new(config_file, cli_options) }

    describe "default log level" do
      let(:cli_options) { {} }

      it "sets the logging level to INFO" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::INFO)
        subject
      end
    end

    describe "when :verbose is specified" do
      let(:cli_options) { { verbose: true } }

      it "sets the logging level to DEBUG" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::DEBUG)
        subject
      end
    end

    describe "when :quiet is specified" do
      let(:cli_options) { { quiet: true } }

      it "sets the logging level to ERROR" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::ERROR)
        subject
      end
    end

    describe "when :quiet and :verbose are specified" do
      let(:cli_options) { { quiet: true, verbose: true } }

      it "sets the logging level to DEBUG when :quiet and :verbose are specified" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::DEBUG)
        subject
      end
    end
  end

  describe "configuration validation" do
    let(:config_file) { 'foo' }

    before(:each) do
      Vcloud::Core::ConfigLoader.any_instance.stub(:load_config).and_return(config)

      allow(Vcloud::Launcher::VappOrchestrator).
        to receive(:provision).and_return(double(:vapp, :power_on => true))
    end

    subject { Vcloud::Launcher::Launch.new(config_file) }

    context "when bootstrap configuration is supplied" do
      context "script_path is missing" do
        let(:config) do
          { vapps: [
              {
                name: "test_vapp_name",
                vdc_name: "Test VDC",
                catalog_name: "default",
                vapp_template_name: "ubuntu-precise",
                bootstrap: {
                  vars: { foo: 'bar' }
                }
              }
            ]
          }
        end

        it "raises MissingConfigurationError" do
          expect{ subject }.
            to raise_error(Vcloud::Launcher::Launch::MissingConfigurationError)
        end
      end

      context "script_path does not exist" do
        let(:config) do
          { vapps: [
              {
                name: "test_vapp_name",
                vdc_name: "Test VDC",
                catalog_name: "default",
                vapp_template_name: "ubuntu-precise",
                bootstrap: {
                  script_path: 'nonexistent_preamble.sh.erb',
                  vars: { foo: 'bar' }
                }
              }
            ]
          }
        end

        it "raises MissingPreambleError" do
          expect{ subject }.
            to raise_error(Vcloud::Launcher::Launch::MissingPreambleError)
        end
      end

      context "script_path is specified, without vars" do
        # Avoid triggering exceptions on missing preamble file.
        before do
          File.stub(:exist?).and_return(true)
          allow(Vcloud::Core.logger).to receive(:info)
        end

        let(:config) do
          { vapps: [
              {
                name: "test_vapp_name",
                vdc_name: "Test VDC",
                catalog_name: "default",
                vapp_template_name: "ubuntu-precise",
                bootstrap: {
                  script_path: 'nonexistent_preamble.sh.erb'
                }
              }
            ]
          }
        end

        it "logs an informative message" do
          # A rather overly specific test to find the message of
          # interest amongst other log messages.
          expect(Vcloud::Core.logger).to receive(:info).with(/without variables to template/)
          subject
        end
      end
    end

    context "when bootstrap configuration is absent" do
      let(:config) do
        { vapps: [
            {
              name: "test_vapp_name",
              vdc_name: "Test VDC",
              catalog_name: "default",
              vapp_template_name: "ubuntu-precise"
            }
          ]
        }
      end

      it "should not raise an error" do
        expect{ subject }.not_to raise_error
      end
    end
  end
end
