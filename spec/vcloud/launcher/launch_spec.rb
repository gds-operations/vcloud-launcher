require 'spec_helper'

module Vcloud
  describe Launcher::Launch do
    context "#run" do
      before(:each) do
        config_loader = double(:config_loader)
        expect(Vcloud::Core::ConfigLoader).to receive(:new).and_return(config_loader)
        @successful_app_1 = {
            :name => "successful app 1",
            :vdc_name => "Test Vdc",
            :catalog => "default",
            :catalog_item => "ubuntu-precise"
        }
        @fake_failing_app = {
            :name => "fake failing app",
            :vdc_name => "wrong vdc",
            :catalog => "default",
            :catalog_item => "ubuntu-precise"
        }
        @successful_app_2 = {
            :name => "successful app 2",
            :vdc_name => "Test Vdc",
            :catalog => "default",
            :catalog_item => "ubuntu-precise"
        }
        expect(config_loader).to receive(:load_config).
          and_return({:vapps => [@successful_app_1, @fake_failing_app, @successful_app_2]})
      end

      it "should stop on failure by default" do
        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(@successful_app_1).and_return(double(:vapp, :power_on => true))
        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(@fake_failing_app).and_raise(RuntimeError.new('failed to find vdc'))
        expect(Vcloud::Launcher::VappOrchestrator).not_to receive(:provision).with(@successful_app_2)

        cli_options = {}
        Vcloud::Launcher::Launch.new.run('input_config_yaml', cli_options)
      end

      it "should continue on error if cli option continue-on-error is set" do
        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(@successful_app_1).and_return(double(:vapp, :power_on => true))
        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(@fake_failing_app).and_raise(RuntimeError.new('failed to find vdc'))
        expect(Vcloud::Launcher::VappOrchestrator).to receive(:provision).with(@successful_app_2).and_return(double(:vapp, :power_on => true))

        cli_options = {"continue-on-error" => true}
        Vcloud::Launcher::Launch.new.run('input_config_yaml', cli_options)
      end

    end

    context "#set_logging_level" do

      it "sets the logging level to DEBUG when :verbose is specified" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::DEBUG)
        Vcloud::Launcher::Launch.new.set_logging_level(:verbose => true)
      end

      it "sets the logging level to ERROR and suppresses progress bar when :quiet is specified" do
        stub_fog_credentials = {}
        expect(::Fog).to receive(:credentials).and_return(stub_fog_credentials)
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::ERROR)
        expect(stub_fog_credentials[:vcloud_director_show_progress]).to be_false
        Vcloud::Launcher::Launch.new.set_logging_level(:quiet => true)
      end

      it "sets the logging level to DEBUG when :quiet and :verbose are specified" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::DEBUG)
        Vcloud::Launcher::Launch.new.set_logging_level(:quiet => true, :verbose => true)
      end

      it "sets the logging level to INFO by default" do
        expect(Vcloud::Core.logger).to receive(:level=).with(Logger::INFO)
        Vcloud::Launcher::Launch.new.set_logging_level({})
      end

    end

  end
end
