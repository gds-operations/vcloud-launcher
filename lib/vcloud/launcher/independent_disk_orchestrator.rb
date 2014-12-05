module Vcloud
  module Launcher
    class IndependentDiskOrchestrator

      def initialize(vm)
        @vm = vm
      end

      def attach(independent_disks_config)
        disk_list = find_disks(independent_disks_config)
        @vm.attach_independent_disks(disk_list)
      end

      def vdc_name
        return @vdc_name if @vdc_name
        parent_vapp = Vcloud::Core::Vapp.get_by_child_vm_id(@vm.id)
        parent_vdc = Vcloud::Core::Vdc.new(parent_vapp.vdc_id)
        @vdc_name = parent_vdc.name
      end

      def find_disks(independent_disks_config)
        independent_disks_config.map do |disk|
          Vcloud::Core::IndependentDisk.get_by_name_and_vdc_name(disk[:name], vdc_name)
        end
      end

    end
  end
end
