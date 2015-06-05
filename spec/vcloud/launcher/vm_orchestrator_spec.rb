require 'spec_helper'

describe Vcloud::Launcher::VmOrchestrator do

  before(:each) do
    @vm_id = "vm-12345678-1234-1234-1234-123456712312"
  end

  let(:vcloud_vm) {
    { :href => "/#{@vm_id}" }
  }
  let(:vapp) {
    double(:vapp, :name => 'web-app1')
  }
  let(:mock_disk_orchestrator) {
    double(:mock_disk_orchestrator)
  }

  subject {
    Vcloud::Launcher::VmOrchestrator.new(vcloud_vm, vapp)
  }

  it "orchestrates customization" do
    vm_config = {
        :hardware_config => {
            :memory => 4096,
            :cpu => 2
        },
        :metadata => {
            :shutdown => true
        },
        :extra_disks => [
            {:name => 'Hard disk 2', :size => '1024'},
            {:name => 'Hard disk 3', :size => '2048'},
        ],
        :independent_disks => [
            {:name => 'test-independent-disk-1' },
            {:name => 'test-independent-disk-2' },
        ],
        :network_connections => [
            {:name => "network1", :ip_address => "198.12.1.21"},
        ],
        :storage_profile => {
            :name => 'basic-storage',
            :href => 'https://vcloud.example.net/api/vdcStorageProfile/000aea1e-a5e9-4dd1-a028-40db8c98d237'
        }
    }
    vm = double(:vm, :id => @vm_id, :vapp_name => 'web-app1', :vapp => vapp, :name => 'test-vm-1')
    expect(Vcloud::Core::Vm).to receive(:new).with(@vm_id, vapp).and_return(vm)

    expect(vm).to receive(:update_name).with('web-app1')
    expect(vm).to receive(:configure_network_interfaces).with(vm_config[:network_connections])
    expect(vm).to receive(:update_storage_profile).with(vm_config[:storage_profile])
    expect(vm).to receive(:update_cpu_count).with(2)
    expect(vm).to receive(:update_memory_size_in_mb).with(4096)
    expect(vm).to receive(:add_extra_disks).with(vm_config[:extra_disks])
    expect(vm).to receive(:insert_cdrom).with(vm_config[:cdrom])
    expect(vm).to receive(:update_metadata).with(vm_config[:metadata])
    expect(Vcloud::Launcher::IndependentDiskOrchestrator).
      to receive(:new).with(vm).and_return(mock_disk_orchestrator)
    expect(mock_disk_orchestrator).to receive(:attach).with(vm_config[:independent_disks])

    allow(vm).to receive(:configure_guest_customization_section).with('')

    subject.customize(vm_config)
  end

  it "if a storage_profile is not specified, customize continues with other customizations" do
    vm = double(:vm, :id => @vm_id, :vapp_name => 'web-app1', :vapp => vapp, :name => 'test-vm-1')
    vm_config = {
      :metadata => {:shutdown => true},
      :network_connections => [{:name => "network1", :ip_address => "198.12.1.21"}],
      :extra_disks => [
        {:size => '1024', :name => 'Hard disk 2', :fs_file => 'mysql', :fs_mntops => 'mysql-something'},
        {:size => '2048', :name => 'Hard disk 3', :fs_file => 'solr', :fs_mntops => 'solr-something'}
      ]
    }
    expect(Vcloud::Core::Vm).to receive(:new).with(@vm_id, vapp).and_return(vm)
    expect(vm).to receive(:update_metadata).with(:shutdown => true)
    expect(vm).to receive(:update_name).with('web-app1')
    expect(vm).to receive(:add_extra_disks).with(vm_config[:extra_disks])
    expect(vm).to receive(:insert_cdrom).with(vm_config[:cdrom])
    expect(vm).to receive(:configure_network_interfaces).with(vm_config[:network_connections])

    allow(vm).to receive(:configure_guest_customization_section)

    subject.customize(vm_config)
  end

  context "when customizing a VM" do
    let(:vm_config_with_bootstrap) do
      {
        hardware_config: {
          memory: 4096,
          cpu: 2
        },
        network_connections: [
          { name: "network1", ip_address: "198.12.1.21" }
        ],
        bootstrap: {
          script_path: '/tmp/bootstrap.erb',
          vars: { message: 'hello world' }
        }
      }
    end

    let(:vm_config_without_bootstrap) do
      {
        hardware_config: {
          memory: 4096,
          cpu: 2
        },
        network_connections: [
          { name: "network1", ip_address: "198.12.1.21" }
        ]
      }
    end

    let(:vm) { double(:vm, id: @vm_id, vapp_name: 'web-app1', vapp: vapp, name: 'test-vm-1') }

    before(:each) do
      Vcloud::Core::Vm.stub(:new).and_return(vm)
      allow(vm).to receive(:update_name)
      allow(vm).to receive(:configure_network_interfaces)
      allow(vm).to receive(:update_cpu_count)
      allow(vm).to receive(:update_memory_size_in_mb)
      allow(vm).to receive(:add_extra_disks)
      allow(vm).to receive(:insert_cdrom)
      allow(vm).to receive(:update_metadata)
    end

    context "when bootstrap configuration is omitted" do
      before { allow(vm).to receive(:configure_guest_customization_section) }

      it "skips preamble processing" do
        expect(Vcloud::Launcher::Preamble).not_to receive(:new)
        expect(Vcloud::Launcher::Preamble).not_to receive(:generate)

        subject.customize(vm_config_without_bootstrap)
      end

      it "uses an empty string as the host preamble" do
        expect(vm).to receive(:configure_guest_customization_section).with('')
        subject.customize(vm_config_without_bootstrap)
      end
    end

    context "when bootstrap configuration is supplied" do
      context "Vcloud::Launcher::Preamble used to generate a preamble" do
        it "instantiates Vcloud::Launcher::Preamble" do
          preamble = double
          allow(preamble).to receive(:generate)
          allow(vm).to receive(:configure_guest_customization_section)

          expect(Vcloud::Launcher::Preamble).to receive(:new).with(vm.vapp_name, vm_config_with_bootstrap).and_return(preamble)

          subject.customize(vm_config_with_bootstrap)
        end

        it "uses Vcloud::Launcher::Preamble.generate to template a preamble" do
          preamble = double
          allow(Vcloud::Launcher::Preamble).to receive(:new).with(vm.vapp_name, vm_config_with_bootstrap).and_return(preamble)
          allow(vm).to receive(:configure_guest_customization_section)

          expect(preamble).to receive(:generate)

          subject.customize(vm_config_with_bootstrap)
        end

        it "passes the generated preamble to configure_guest_customization_section" do
          preamble = double
          allow(Vcloud::Launcher::Preamble).to receive(:new).with(vm.vapp_name, vm_config_with_bootstrap).and_return(preamble)
          allow(preamble).to receive(:generate).and_return('FAKE_PREAMBLE')

          expect(vm).to receive(:configure_guest_customization_section).with('FAKE_PREAMBLE')

          subject.customize(vm_config_with_bootstrap)
        end
      end
    end
  end
end
