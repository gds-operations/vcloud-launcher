require 'spec_helper'

describe Vcloud::Launcher::IndependentDiskOrchestrator do

  let(:mock_vm) {
    double(
      :vm,
      :id => 'vm-12341234-1234-1234-1234-123412340001',
      :vapp_name => 'web-app1',
      :name => 'test-vm-1'
    )
  }

  let(:mock_parent_vapp) {
    double(
      :vapp,
      :id => 'vapp-12341234-1234-1234-1234-123412340000',
      :name => 'web-app1',
      :vdc_id => '12341234-1234-1234-1234-123412349999',
    )
  }

  let(:mock_parent_vdc) {
    double(
      :vdc,
      :id => '12341234-1234-1234-1234-123412349999',
      :name => 'test-vdc-1',
    )
  }

  let(:independent_disk_config) {
    [
      {:name => 'test-independent-disk-1' },
      {:name => 'test-independent-disk-2' },
    ]
  }

  let(:mock_disk_1) {
    double(
      :independent_disk_1,
      :id => '12341234-1234-1234-123411110001',
      :name => 'test-independent-disk-1'
    )
  }

  let(:mock_disk_2) {
    double(
      :independent_disk_2,
      :id => '12341234-1234-1234-123411110002',
      :name => 'test-independent-disk-2'
    )
  }

  subject { Vcloud::Launcher::IndependentDiskOrchestrator.new(mock_vm) }

  describe "#vdc_name" do
  end

  describe "#find_disks" do

    before(:each) do
      expect(Vcloud::Core::Vapp).to receive(:get_by_child_vm_id).with(mock_vm.id).
        and_return(mock_parent_vapp)
      expect(Vcloud::Core::Vdc).to receive(:new).with(mock_parent_vapp.vdc_id).
        and_return(mock_parent_vdc)
    end

    it "finds Vcloud::Core::IndependentDisk objects from our configuration" do
      expect(Vcloud::Core::IndependentDisk).
        to receive(:get_by_name_and_vdc_name).
        with(independent_disk_config[0][:name], mock_parent_vdc.name).
        ordered.
        and_return(mock_disk_1)
      expect(Vcloud::Core::IndependentDisk).
        to receive(:get_by_name_and_vdc_name).
        with(independent_disk_config[1][:name], mock_parent_vdc.name).
        ordered.
        and_return(mock_disk_2)
      expect(subject.find_disks(independent_disk_config)).
        to eq([mock_disk_1, mock_disk_2])
    end

  end

  describe "#attach" do
    it "orchestrates attachment of independent disks to a VM" do
      expect(subject).to receive(:find_disks).and_return([mock_disk_1, mock_disk_2])
      expect(mock_vm).to receive(:attach_independent_disks).
        with([mock_disk_1, mock_disk_2]).
        and_return(true)
      expect(subject.attach(independent_disk_config)).to be_true
    end
  end

end
