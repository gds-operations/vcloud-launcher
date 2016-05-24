module Vcloud
  module Launcher
    class VappOrchestrator

      def self.provision(vapp_config, dry_run = false)
        name, vdc_name = vapp_config[:name], vapp_config[:vdc_name]

        vapp_existing = Vcloud::Core::Vapp.get_by_name_and_vdc_name(name, vdc_name)
        if vapp_existing
          Vcloud::Core.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
          return vapp_existing
        end

        template_name = vapp_config[:vapp_template_name] || vapp_config[:catalog_item]
        catalog_name = vapp_config[:catalog_name] || vapp_config[:catalog]
        template = Vcloud::Core::VappTemplate.get(template_name, catalog_name)
        template_id = template.id
        network_names = extract_vm_networks(vapp_config)
        if dry_run
          Vcloud::Core.logger.info("Instantiating new vApp #{name} in vDC '#{vdc_name}'")
        else
          vapp = Vcloud::Core::Vapp.instantiate(name, network_names, template_id, vdc_name)
          Vcloud::Launcher::VmOrchestrator.new(vapp.vms.first, vapp).customize(vapp_config[:vm]) if vapp_config[:vm]

          vapp
        end
      end

      def self.extract_vm_networks(config)
        if (config[:vm] && config[:vm][:network_connections])
          config[:vm][:network_connections].collect { |h| h[:name] }
        end
      end

    end
  end
end
