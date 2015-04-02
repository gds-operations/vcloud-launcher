require 'spec_helper'

describe Vcloud::Launcher::VappOrchestrator do
  # Testing class methods rather than instance methods.
  let(:subject) { Vcloud::Launcher::VappOrchestrator }

  context "provision a vapp" do

    let(:mock_vcloud_vm) {
      double(:vm)
    }
    let(:mock_vcloud_vm_pair) {
      [double(:vm), double(:vm)]
    }
    let(:mock_vapp) {
      double(:vapp, :vms => [mock_vcloud_vm], :reload => self)
    }
    let(:mock_vapp_with_vm_pair) {
      double(:vapp, :vms => mock_vcloud_vm_pair, :reload => self)
    }
    let(:mock_vm_orchestrator) {
      double(:vm_orchestrator, :customize => true)
    }

    before(:each) do
      @config = {
        :name => 'test-vapp-1',
        :vdc_name => 'test-vdc-1',
        :catalog_name => 'org-1-catalog',
        :vapp_template_name => 'org-1-template',
        :vm => {
          :network_connections => [{:name => 'org-vdc-1-net-1'}]
        },
      }
    end

    it "should return a vapp if it already exists" do
      existing_vapp = double(:vapp, :name => 'existing-vapp-1')

      expect(Vcloud::Core::Vapp).to receive(:get_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').and_return(existing_vapp)
      expect(Vcloud::Core.logger).to receive(:info).with('Found existing vApp test-vapp-1 in vDC \'test-vdc-1\'. Skipping.')
      actual_vapp = subject.provision @config
      expect(actual_vapp).not_to be_nil
      expect(actual_vapp).to eq(existing_vapp)
    end

    it "should create a vapp if it does not exist" do
      #this test highlights the problems in vapp

      expect(Vcloud::Core::Vapp).to receive(:get_by_name_and_vdc_name).with('test-vapp-1', 'test-vdc-1').and_return(nil)
      expect(Vcloud::Core::VappTemplate).to receive(:get).with('org-1-template', 'org-1-catalog').and_return(double(:vapp_template, :id => 1))

      expect(Vcloud::Core::Vapp).to receive(:instantiate).with('test-vapp-1', ['org-vdc-1-net-1'], 1, 'test-vdc-1')
      .and_return(mock_vapp)
      expect(Vcloud::Launcher::VmOrchestrator).to receive(:new).with(mock_vcloud_vm, mock_vapp).and_return(mock_vm_orchestrator)

      new_vapp = subject.provision @config
      expect(new_vapp).to eq(mock_vapp)
    end

    it "should create a vapp with multiple vms if it does not exist" do
      config = @config.clone
      config[:vm] = [
        {
          :name => "vm1",
          :network_connections => [{:name => 'org-vdc-1-net-1'}],
        },
        {
          :name => "vm2",
          :network_connections => [{:name => 'org-vdc-1-net-1'}],
        }
      ]
      expect(Vcloud::Core::Vapp).to receive(:get_by_name_and_vdc_name)
        .with('test-vapp-1', 'test-vdc-1')
        .and_return(nil)

      expect(Vcloud::Core::VappTemplate).to receive(:get)
        .with('org-1-template', 'org-1-catalog')
        .and_return(double(:vapp_template, :id => 1))

      expect(Vcloud::Core::Vapp).to receive(:instantiate)
        .with('test-vapp-1', [["org-vdc-1-net-1"], ["org-vdc-1-net-1"]], 1, 'test-vdc-1')
        .and_return(mock_vapp_with_vm_pair)

      expect(Vcloud::Launcher::VmOrchestrator).to receive(:new)
        .with(mock_vcloud_vm_pair.first, mock_vapp_with_vm_pair)
        .and_return(mock_vm_orchestrator)

      expect(Vcloud::Launcher::VmOrchestrator).to receive(:new)
        .with(mock_vcloud_vm_pair.last, mock_vapp_with_vm_pair)
        .and_return(mock_vm_orchestrator)

      new_vapp = subject.provision config
      expect(new_vapp).to eq(mock_vapp_with_vm_pair)
    end

    context "deprecated config items" do
      let(:mock_vapp_template) {
        double(:vapp_template, :id => 2)
      }
      before(:each) {
        allow(Vcloud::Core::Vapp).to receive(:get_by_name_and_vdc_name)
        allow(Vcloud::Core::Vapp).to receive(:instantiate).and_return(mock_vapp)
        allow(Vcloud::Launcher::VmOrchestrator).to receive(:new).and_return(mock_vm_orchestrator)
      }

      it "should use catalog_item when vapp_template_name is not present" do
        config = @config.clone
        config.delete(:vapp_template_name)
        config[:catalog_item] = 'deprecated-template'

        expect(Vcloud::Core::VappTemplate).to receive(:get).with('deprecated-template', 'org-1-catalog').and_return(mock_vapp_template)
        Vcloud::Launcher::VappOrchestrator.provision(config)
      end

      it "should use catalog when catalog_name is not present" do
        config = @config.clone
        config.delete(:catalog_name)
        config[:catalog] = 'deprecated-catalog'

        expect(Vcloud::Core::VappTemplate).to receive(:get).with('org-1-template', 'deprecated-catalog').and_return(mock_vapp_template)
        Vcloud::Launcher::VappOrchestrator.provision(config)
      end
    end

  end
end
