module Vcloud
  module Launcher
    class VappOrchestrator

      def self.provision(vapp_config)
        name, vdc_name = vapp_config[:name], vapp_config[:vdc_name]

        vapp_existing = Vcloud::Core::Vapp.get_by_name_and_vdc_name(name, vdc_name)
        # FIXME: if vapp exists, does it contain all configured VMs?
        if vapp_existing
          Vcloud::Core.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
          return vapp_existing
        end

        template_name = vapp_config[:vapp_template_name] || vapp_config[:catalog_item]
        catalog_name = vapp_config[:catalog_name] || vapp_config[:catalog]
        template = Vcloud::Core::VappTemplate.get(template_name, catalog_name)
        template_id = template.id

        network_names = extract_vm_networks(vapp_config)
        vapp = Vcloud::Core::Vapp.instantiate(name, network_names, template_id, vdc_name)

        vm_config = vapp_config[:vm]

        case vm_config
        when Hash
          Vcloud::Launcher::VmOrchestrator.new(vapp.vms.first, vapp).customize(vm_config)
        when Array
          vm_config.each.with_index do |vm, i|
            Vcloud::Launcher::VmOrchestrator.new(vapp.vms[i], vapp).customize(vm)
          end
        else
          raise Vcloud::Launcher::Launch::MissingConfigurationError,
            "Config must have vm section, and must be a Hash or an Array"
        end

        # Vcloud::Launcher::VmOrchestrator.new(vapp.vms.first, vapp).customize(vapp_config[:vm]) if vapp_config[:vm]

        vapp
      end

      def self.vm_config_present?(config)
        config[:vm]
      end

      def self.extract_vm_networks(config)
        return unless vm_config_present? config
        vm_config = config[:vm]
        case vm_config
        when Hash
          config[:vm][:network_connections].collect { |h| h[:name] }
        when Array
          vm_config.map { |c| c[:network_connections].collect { |h| h[:name] } }
        end
      end

    end
  end
end
