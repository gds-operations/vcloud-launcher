require 'spec_helper'

describe Vcloud::Launcher::Schema::LAUNCHER_VAPPS do

  let(:schema) { Vcloud::Launcher::Schema::LAUNCHER_VAPPS }

  context "independent_disks section is present" do

    let(:config) do
      { vapps: [
          {
            name: "test_vapp_name",
            vdc_name: "Test VDC",
            catalog_name: "default",
            vapp_template_name: "ubuntu-precise",
            vm: {
              independent_disks: [ { name: 'indydisk-1' }, { name: 'indydisk-2' } ],
            }
          }
        ]
      }
    end

    it "validates successfully" do
      validation = Vcloud::Core::ConfigValidator.new(:base, config, schema)
      expect(validation.valid?).to be true
    end

  end

  context "independent_disks section is present but not an array" do

    let(:config) do
      { vapps: [
          {
            name: "test_vapp_name",
            vdc_name: "Test VDC",
            catalog_name: "default",
            vapp_template_name: "ubuntu-precise",
            vm: {
              independent_disks: 'indydisk-1'
            }
          }
        ]
      }
    end

    it "does not validate successfully" do
      validation = Vcloud::Core::ConfigValidator.new(:base, config, schema)
      expect(validation.valid?).to be false
      expect(validation.errors).to eq(['independent_disks is not an array'])
    end

  end

  context "independent_disks section is present but not an array of hashes" do

    let(:config) do
      { vapps: [
          {
            name: "test_vapp_name",
            vdc_name: "Test VDC",
            catalog_name: "default",
            vapp_template_name: "ubuntu-precise",
            vm: {
              independent_disks: [ 'indydisk-1', 'indydisk-2' ]
            }
          }
        ]
      }
    end

    it "does not validate successfully" do
      validation = Vcloud::Core::ConfigValidator.new(:base, config, schema)
      expect(validation.valid?).to be false
      expect(validation.errors).to eq(
        ['independent_disks: is not a hash', 'independent_disks: is not a hash']
      )
    end

  end

  context "independent_disks section is present and a hash, but not contain a :name parameter" do

    let(:config) do
      { vapps: [
          {
            name: "test_vapp_name",
            vdc_name: "Test VDC",
            catalog_name: "default",
            vapp_template_name: "ubuntu-precise",
            vm: {
              independent_disks: [ { nametypo: 'indydisk-1'} ]
            }
          }
        ]
      }
    end

    it "does not validate successfully" do
      validation = Vcloud::Core::ConfigValidator.new(:base, config, schema)
      expect(validation.valid?).to be false
      expect(validation.errors).to eq([
        "independent_disks: parameter 'nametypo' is invalid",
        "independent_disks: missing 'name' parameter"
      ])
    end

  end

end
