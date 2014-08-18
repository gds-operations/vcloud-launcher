require 'spec_helper'
require 'vcloud/tools/tester'

describe Vcloud::Launcher::Launch do
  context "storage profile", :take_too_long => true do
    before(:all) do
      @test_data = define_test_data
      @config_yaml = ErbHelper.convert_erb_template_to_yaml(@test_data, File.join(File.dirname(__FILE__), 'data/storage_profile.yaml.erb'))
      @api_interface = Vcloud::Core::ApiInterface.new
      Vcloud::Launcher::Launch.new(@config_yaml, {'dont-power-on' => true}).run

      @vapp_query_result_1 = @api_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_1], @test_data[:vdc_1_name])
      @vapp_id_1 = @vapp_query_result_1[:href].split('/').last
      @vapp_1 = @api_interface.get_vapp @vapp_id_1
      @vm_1 = @vapp_1[:Children][:Vm].first

      @vapp_query_result_2 = @api_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_2], @test_data[:vdc_2_name])
      @vapp_id_2 = @vapp_query_result_2[:href].split('/').last
      @vapp_2 = @api_interface.get_vapp @vapp_id_2
      @vm_2 = @vapp_2[:Children][:Vm].first

      @vapp_query_result_3 = @api_interface.get_vapp_by_name_and_vdc_name(@test_data[:vapp_name_3], @test_data[:vdc_1_name])
      @vapp_id_3 = @vapp_query_result_3[:href].split('/').last
      @vapp_3 = @api_interface.get_vapp @vapp_id_3
      @vm_3 = @vapp_3[:Children][:Vm].first

    end

    it "vdc 1 should have a storage profile without the href being specified" do
      expect(@vm_1[:StorageProfile][:name]).to eq(@test_data[:storage_profile])
    end

    it "vdc 1's storage profile should have the expected href" do
      expect(@vm_1[:StorageProfile][:href]).to eq(@test_data[:vdc_1_sp_href])
    end

    it "vdc 2 should have the same named storage profile as vdc 1" do
      expect(@vm_2[:StorageProfile][:name]).to eq(@test_data[:storage_profile])
    end

    it "the storage profile in vdc 2 should have a different href to the storage profile in vdc 1" do
      expect(@vm_2[:StorageProfile][:href]).to eq(@test_data[:vdc_2_sp_href])
    end

    it "when a storage profile is not specified, vm uses the default" do
      expect(@vm_3[:StorageProfile][:name]).to eq(@test_data[:default_storage_profile_name])
      expect(@vm_3[:StorageProfile][:href]).to eq(@test_data[:default_storage_profile_href])
    end

    after(:all) do
      unless ENV['VCLOUD_TOOLS_RSPEC_NO_DELETE_VAPP']
        File.delete @config_yaml
        expect(@api_interface.delete_vapp(@vapp_id_1)).to eq(true)
        expect(@api_interface.delete_vapp(@vapp_id_2)).to eq(true)
        expect(@api_interface.delete_vapp(@vapp_id_3)).to eq(true)
      end
    end

  end

end

def define_test_data
  config_file = File.join(File.dirname(__FILE__),
    "../vcloud_tools_testing_config.yaml")
  required_user_parameters = [
    "vdc_1_name",
    "vdc_2_name",
    "catalog",
    "vapp_template",
    "storage_profile",
    "vdc_1_storage_profile_href",
    "vdc_2_storage_profile_href",
    "default_storage_profile_name",
    "default_storage_profile_href",
  ]

  parameters = Vcloud::Tools::Tester::TestSetup.new(config_file, required_user_parameters).test_params
  {
    vapp_name_1: "vdc-1-sp-#{Time.now.strftime('%s')}",
    vapp_name_2: "vdc-2-sp-#{Time.now.strftime('%s')}",
    vapp_name_3: "vdc-3-sp-#{Time.now.strftime('%s')}",
    vdc_1_name: parameters.vdc_1_name,
    vdc_2_name: parameters.vdc_2_name,
    catalog: parameters.catalog,
    vapp_template: parameters.vapp_template,
    storage_profile: parameters.storage_profile,
    vdc_1_sp_href: parameters.vdc_1_storage_profile_href,
    vdc_2_sp_href: parameters.vdc_2_storage_profile_href,
    default_storage_profile_name: parameters.default_storage_profile_name,
    default_storage_profile_href: parameters.default_storage_profile_href,
    nonsense_storage_profile: "nonsense-storage-profile-name",
    bootstrap_script: File.join(File.dirname(__FILE__), "data/basic_preamble_test.erb"),
  }
end
