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
      @fog_interface = Vcloud::Fog::ServiceInterface.new

      Vcloud::Launcher::Launch.new.run(@minimum_data_yaml, {"dont-power-on" => true})

      vapp_query_result = @fog_interface.get_vapp_by_name_and_vdc_name(test_data_1[:vapp_name], test_data_1[:vdc_name])
      @provisioned_vapp_id = vapp_query_result[:href].split('/').last
      provisioned_vapp = @fog_interface.get_vapp @provisioned_vapp_id

      provisioned_vapp.should_not be_nil
      provisioned_vapp[:name].should eq(test_data_1[:vapp_name])
      provisioned_vapp[:Children][:Vm].count.should eq(1)
    end

    after(:each) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @minimum_data_yaml
        @fog_interface.delete_vapp(@provisioned_vapp_id).should eq(true)
      end
    end
  end

  context "happy path" do
    before(:all) do
      @test_data = define_test_data
      @config_yaml = ErbHelper.convert_erb_template_to_yaml(@test_data, File.join(File.dirname(__FILE__), 'data/happy_path.yaml.erb'))
      @fog_interface = Vcloud::Fog::ServiceInterface.new
      Vcloud::Launcher::Launch.new.run(@config_yaml, { "dont-power-on" => true })

      @vapp_query_result = @fog_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name], @test_data[:vdc_name])
      @vapp_id = @vapp_query_result[:href].split('/').last

      @vapp = @fog_interface.get_vapp @vapp_id
      @vm = @vapp[:Children][:Vm].first
      @vm_id = @vm[:href].split('/').last

      @vm_metadata = Vcloud::Core::Vm.get_metadata @vm_id
    end

    context 'provision vapp' do
      it 'should create a vapp' do
        @vapp[:name].should eq(@test_data[:vapp_name])
        @vapp[:'ovf:NetworkSection'][:'ovf:Network'].count.should eq(2)
        vapp_networks = @vapp[:'ovf:NetworkSection'][:'ovf:Network'].collect { |connection| connection[:ovf_name] }
        vapp_networks.should =~ [@test_data[:network_1], @test_data[:network_2]]
      end

      it "should create vm within vapp" do
        @vm.should_not be_nil
      end

    end

    context "customize vm" do
      it "change cpu for given vm" do
        extract_memory(@vm).should eq('8192')
        extract_cpu(@vm).should eq('4')
      end

      it "should have added the right number of metadata values" do
        @vm_metadata.count.should eq(6)
      end

      it "the metadata should be equivalent to our input" do
        @vm_metadata[:is_true].should eq(true)
        @vm_metadata[:is_integer].should eq(-999)
        @vm_metadata[:is_string].should eq('Hello World')
      end

      it "should attach extra hard disks to vm" do
        disks = extract_disks(@vm)
        disks.count.should eq(3)
        [{:name => 'Hard disk 2', :size => '1024'}, {:name => 'Hard disk 3', :size => '2048'}].each do |new_disk|
          disks.should include(new_disk)
        end
      end

      it "should configure the vm network interface" do
        vm_network_connection = @vm[:NetworkConnectionSection][:NetworkConnection]
        vm_network_connection.should_not be_nil
        vm_network_connection.count.should eq(2)


        primary_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network_1] }
        primary_nic[:network].should eq(@test_data[:network_1])
        primary_nic[:NetworkConnectionIndex].should eq(@vm[:NetworkConnectionSection][:PrimaryNetworkConnectionIndex])
        primary_nic[:IpAddress].should eq(@test_data[:network_1_ip])
        primary_nic[:IpAddressAllocationMode].should eq('MANUAL')

        second_nic = vm_network_connection.detect { |connection| connection[:network] == @test_data[:network_2] }
        second_nic[:network].should eq(@test_data[:network_2])
        second_nic[:NetworkConnectionIndex].should eq('1')
        second_nic[:IpAddress].should eq(@test_data[:network_2_ip])
        second_nic[:IpAddressAllocationMode].should eq('MANUAL')

      end

      it 'should assign guest customization script to the VM' do
        @vm[:GuestCustomizationSection][:CustomizationScript].should =~ /message: hello world/
        @vm[:GuestCustomizationSection][:ComputerName].should eq(@test_data[:vapp_name])
      end

      it "should assign storage profile to the VM" do
        @vm[:StorageProfile][:name].should eq(@test_data[:storage_profile])
      end

    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
        @fog_interface.delete_vapp(@vapp_id).should eq(true)
      end
    end

  end

  def extract_memory(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '4' }[:'rasd:VirtualQuantity']
  end

  def extract_cpu(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].detect { |i| i[:'rasd:ResourceType'] == '3' }[:'rasd:VirtualQuantity']
  end

  def extract_disks(vm)
    vm[:'ovf:VirtualHardwareSection'][:'ovf:Item'].collect { |d|
      {:name => d[:"rasd:ElementName"], :size => (d[:"rasd:HostResource"][:ns12_capacity] || d[:"rasd:HostResource"][:vcloud_capacity])} if d[:'rasd:ResourceType'] == '17'
    }.compact
  end

  def define_test_data
    config_file = File.join(File.dirname(__FILE__),
      "../vcloud_tools_testing_config.yaml")
    parameters = Vcloud::Tools::Tester::TestParameters.new(config_file)
    {
      vapp_name: "vapp-vcloud-tools-tests-#{Time.now.strftime('%s')}",
      vdc_name: parameters.vdc_1_name,
      catalog: parameters.catalog,
      vapp_template: parameters.vapp_template,
      storage_profile: parameters.storage_profile,
      network_1: parameters.network_1,
      network_2: parameters.network_2,
      network_1_ip: parameters.network_1_ip,
      network_2_ip: parameters.network_2_ip,
      bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
      date_metadata: DateTime.parse('2013-10-23 15:34:00 +0000')
    }
  end
end
