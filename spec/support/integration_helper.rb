module IntegrationHelper

  def self.create_test_case_independent_disks(number_of_disks,
                                  vdc_name,
                                  size,
                                  prefix = "vcloud-launcher-tests"
                                 )
    timestamp_in_s = Time.new.to_i
    base_disk_name = "#{prefix}-#{timestamp_in_s}-"
    disk_list = []
    vdc = Vcloud::Core::Vdc.get_by_name(vdc_name)
    number_of_disks.times do |index|
      disk_list << Vcloud::Core::IndependentDisk.create(
        vdc,
        base_disk_name + index.to_s,
        size,
      )
    end
    disk_list
  end

  def self.delete_independent_disks(disk_list)
    disk_list.each do |disk|
      disk.destroy
    end
  end

end
