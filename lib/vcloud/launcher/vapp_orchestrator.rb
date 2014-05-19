module Vcloud
  module Launcher
    class VappOrchestrator

      def self.provision(vapp_config)
        name, vdc_name = vapp_config[:name], vapp_config[:vdc_name]

        vapp_existing = Vcloud::Core::Vapp.get_by_name_and_vdc_name(name, vdc_name)
        if vapp_existing
          Vcloud::Core.logger.info("Found existing vApp #{name} in vDC '#{vdc_name}'. Skipping.")
          return vapp_existing
        end

        template_name = vapp_config[:vapp_template_name] || vapp_config[:catalog_item]
        template = Vcloud::Core::VappTemplate.get(template_name, vapp_config[:catalog])
        template_id = template.id

        network_names = extract_vm_networks(vapp_config)
        vapp = Vcloud::Core::Vapp.instantiate(name, network_names, template_id, vdc_name)
        Vcloud::Launcher::VmOrchestrator.new(vapp.fog_vms.first, vapp).customize(vapp_config[:vm]) if vapp_config[:vm]

        vapp
      end

      def self.provision_schema
        {
          type: 'hash',
          required: true,
          allowed_empty: false,
          internals: {
            name:               { type: 'string', required: true, allowed_empty: false },
            vdc_name:           { type: 'string', required: true, allowed_empty: false },
            catalog:            { type: 'string', required: true, allowed_empty: false },
            catalog_item:       { type: 'string', deprecated_by: 'vapp_template_name', allowed_empty: false },
            vapp_template_name: { type: 'string', required: true, allowed_empty: false },
            vm: Vcloud::Launcher::VmOrchestrator.customize_schema,
          }
        }
      end

      def self.extract_vm_networks(config)
        if (config[:vm] && config[:vm][:network_connections])
          config[:vm][:network_connections].collect { |h| h[:name] }
        end
      end

    end
  end
end
