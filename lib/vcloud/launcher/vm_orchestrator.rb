module Vcloud
  module Launcher
    class VmOrchestrator

      def initialize vcloud_vm, vapp
        vm_id = vcloud_vm[:href].split('/').last
        @vm = Core::Vm.new(vm_id, vapp)
      end

      def customize(vm_config)
        @vm.update_name(@vm.vapp_name)
        @vm.configure_network_interfaces vm_config[:network_connections]
        @vm.update_storage_profile(vm_config[:storage_profile]) if vm_config[:storage_profile]
        if vm_config[:hardware_config]
          @vm.update_cpu_count(vm_config[:hardware_config][:cpu])
          @vm.update_memory_size_in_mb(vm_config[:hardware_config][:memory])
        end
        @vm.add_extra_disks(vm_config[:extra_disks])
        @vm.update_metadata(vm_config[:metadata])

        preamble = vm_config[:bootstrap] ? generate_preamble(vm_config) : ''

        @vm.configure_guest_customization_section(preamble)
      end

      private

      def generate_preamble(vm_config)
        preamble = ::Vcloud::Launcher::Preamble.new(@vm.vapp_name, vm_config)
        preamble.generate
      end
    end
  end
end
