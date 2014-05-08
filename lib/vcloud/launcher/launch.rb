module Vcloud
  module Launcher
    class Launch

      def initialize
        @config_loader = Vcloud::Core::ConfigLoader.new
      end

      def run(config_file = nil, cli_options = {})
        set_logging_level(cli_options)
        config = @config_loader.load_config(config_file, config_schema)
        config[:vapps].each do |vapp_config|
          Vcloud::Core.logger.info("Provisioning vApp #{vapp_config[:name]}.")
          begin
            vapp = ::Vcloud::Launcher::VappOrchestrator.provision(vapp_config)
            #methadone sends option starting with 'no' as false.
            vapp.power_on unless cli_options["dont-power-on"]
            Vcloud::Core.logger.info("Provisioned vApp #{vapp_config[:name]} successfully.")
          rescue RuntimeError => e
            Vcloud::Core.logger.error("Failure: Could not provision vApp: #{e.message}")
            break unless cli_options["continue-on-error"]
          end

        end
      end

      def config_schema
        {
          type: 'hash',
          allowed_empty: false,
          permit_unknown_parameters: true,
          internals: {
            vapps: {
            type: 'array',
            required: false,
            allowed_empty: true,
            each_element_is: ::Vcloud::Launcher::VappOrchestrator.provision_schema
          },
        }
      }
      end

      def set_logging_level(cli_options)
        if cli_options[:verbose]
          Vcloud::Core.logger.level = Logger::DEBUG
        elsif cli_options[:quiet]
          Vcloud::Core.logger.level = Logger::ERROR
          ::Fog.credentials[:vcloud_director_show_progress] = false
        else
          Vcloud::Core.logger.level = Logger::INFO
        end
      end

    end
  end
end
