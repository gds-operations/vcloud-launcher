require 'spec_helper'
require 'pp'
require 'erb'
require 'ostruct'
require 'vcloud/tools/tester'

describe Vcloud::Launcher::Launch do
  context "with minimum input setup" do
    it "should provision vapp with single vm" do
      test_data_1 = define_test_data
      minimum_data_erb = File.join(File.dirname(__FILE__), 'data/minimum_data_setup.yaml.erb')
      @minimum_data_yaml = ErbHelper.convert_erb_template_to_yaml(test_data_1, minimum_data_erb)
      @api_interface = Vcloud::Core::ApiInterface.new

      Vcloud::Launcher::Launch.new(@minimum_data_yaml, {"dont-power-on" => true}).run

      vapp_query_result = @api_interface.get_vapp_by_name_and_vdc_name(test_data_1[:vapp_name], test_data_1[:vdc_name])
      @provisioned_vapp_id = vapp_query_result[:href].split('/').last
      provisioned_vapp = @api_interface.get_vapp @provisioned_vapp_id

      expect(provisioned_vapp).not_to be_nil
      expect(provisioned_vapp[:name]).to eq(test_data_1[:vapp_name])
      expect(provisioned_vapp[:Children][:Vm].count).to eq(1)
    end

    after(:each) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @minimum_data_yaml
        expect(@api_interface.delete_vapp(@provisioned_vapp_id)).to eq(true)
      end
    end
  end

  context "happy path" do
    before(:all) do
      @test_data = define_test_data
      @config_yaml = ErbHelper.convert_erb_template_to_yaml(@test_data, File.join(File.dirname(__FILE__), 'data/happy_path.yaml.erb'))
      @api_interface = Vcloud::Core::ApiInterface.new
      Vcloud::Launcher::Launch.new(@config_yaml, { "dont-power-on" => true }).run

      @vapp_query_result = @api_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name], @test_data[:vdc_name])
      @vapp_id = @vapp_query_result[:href].split('/').last

      @vapp = @api_interface.get_vapp @vapp_id
      @vm = @vapp[:Children][:Vm].first
      @vm_id = @vm[:href].split('/').last

      @vm_metadata = Vcloud::Core::Vm.get_metadata @vm_id
    end

    context 'provision vapp' do
      it 'should create a vapp' do
        expect(@vapp[:name]).to eq(@test_data[:vapp_name])
        expect(@vapp[:'ovf:NetworkSection'][:'ovf:Network'].count).to eq(2)
        vapp_networks = @vapp[:'ovf:NetworkSection'][:'ovf:Network'].collect { |connection| connection[:ovf_name] }
        expect(vapp_networks).to match_array([@test_data[:network_1], @test_data[:network_2]])
      end

      it "should create vm within vapp" do
        expect(@vm).not_to be_nil
      end

    end

    context "customize vm" do
      it "change cpu for given vm" do
        expect(extract_memory(@vm)).to eq('8192')
        expect(extract_cpu(@vm)).to eq('4')
      end

      it "should have added the right number of metadata values" do
        expect(@vm_metadata.count).to eq(6)
      end

      it "the metadata should be equivalent to our input" do
        expect(@vm_metadata[:is_true]).to eq(true)
        expect(@vm_metadata[:is_integer]).to eq(-999)
        expect(@vm_metadata[:is_string]).to eq('Hello World')
      end

      it "should attach extra local hard disks to vm" do
        disks = extract_local_disks(@vm)
        expect(disks.count).to eq(3)
        [{:name => 'Hard disk 2', :size => '1024'}, {:name => 'Hard disk 3', :size => '2048'}].each do |new_disk|
          expect(disks).to include(new_disk)
        end
      end

      it "should attach extra independent disks to vm" do
        disks = extract_independent_disks(@vm)
        expect(disks.count).to eq(1)
        [{:name => 'Hard disk 4'}].each do |new_disk|
          expect(disks).to include(new_disk)
        end
      end

      it "should configure the vm network interface" do
        vm_network_connection = @vm[:NetworkConnectionSection][:NetworkConnection]
        expect(vm_network_connection).not_to be_nil
        expect(vm_network_connection.count).to eq(2)


        primary_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network_1] }
        expect(primary_nic[:network]).to eq(@test_data[:network_1])
        expect(primary_nic[:NetworkConnectionIndex]).to eq(@vm[:NetworkConnectionSection][:PrimaryNetworkConnectionIndex])
        expect(primary_nic[:IpAddress]).to eq(@test_data[:network_1_ip])
        expect(primary_nic[:IpAddressAllocationMode]).to eq('MANUAL')

        second_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network_2] }
        expect(second_nic[:network]).to eq(@test_data[:network_2])
        expect(second_nic[:NetworkConnectionIndex]).to eq('1')
        expect(second_nic[:IpAddress]).to eq(@test_data[:network_2_ip])
        expect(second_nic[:IpAddressAllocationMode]).to eq('MANUAL')

      end

      it 'should assign guest customization script to the VM' do
        expect(@vm[:GuestCustomizationSection][:CustomizationScript]).to match(/message: hello world/)
        expect(@vm[:GuestCustomizationSection][:ComputerName]).to eq(@test_data[:vapp_name])
      end

      it "should assign storage profile to the VM" do
        expect(@vm[:StorageProfile][:name]).to eq(@test_data[:storage_profile])
      end

    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
        expect(@api_interface.delete_vapp(@vapp_id)).to eq(true)
      end
    end

  end

  def extract_memory(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '4' }[:'rasd:VirtualQuantity']
  end

  def extract_cpu(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '3' }[:'rasd:VirtualQuantity']
  end

  def extract_local_disks(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].collect { |d|
      if d[:'rasd:ResourceType'] == '17' && ! d[:'rasd:HostResource'].key?(:vcloud_disk)
        {
          :name => d[:"rasd:ElementName"],
          :size => (
            d[:"rasd:HostResource"][:ns12_capacity] || d[:"rasd:HostResource"][:vcloud_capacity]
          )
        }
      end
    }.compact
  end

  def extract_independent_disks(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].collect { |d|
      if d[:'rasd:ResourceType'] == '17' && d[:'rasd:HostResource'].key?(:vcloud_disk)
        {
          :name => d[:"rasd:ElementName"]
        }
      end
    }.compact
  end

  def define_test_data
    config_file = File.join(File.dirname(__FILE__),
      "../vcloud_tools_testing_config.yaml")
    required_user_params = [
      "vdc_1_name",
      "catalog",
      "vapp_template",
      "existing_independent_disk_1",
      "storage_profile",
      "network_1",
      "network_2",
      "network_1_ip",
      "network_2_ip",
    ]

    parameters = Vcloud::Tools::Tester::TestSetup.new(config_file, required_user_params).test_params
    {
      vapp_name: "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
      vdc_name: parameters.vdc_1_name,
      catalog: parameters.catalog,
      vapp_template: parameters.vapp_template,
      storage_profile: parameters.storage_profile,
      existing_independent_disk_1: parameters.existing_independent_disk_1,
      network_1: parameters.network_1,
      network_2: parameters.network_2,
      network_1_ip: parameters.network_1_ip,
      network_2_ip: parameters.network_2_ip,
      bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
      date_metadata: DateTime.parse('2013-10-23 15:34:00 +0000')
    }
  end
end
