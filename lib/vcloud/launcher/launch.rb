module Vcloud
  module Launcher
    class Launch

      def initialize
        @config_loader = Vcloud::Core::ConfigLoader.new
      end

      def run(config_file = nil, cli_options = {})
        set_logging_level(cli_options)
        config = @config_loader.load_config(config_file, Vcloud::Launcher::Schema::LAUNCHER_VAPPS)
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

      def set_logging_level(cli_options)
        if cli_options[:verbose]
          Vcloud::Core.logger.level = Logger::DEBUG
        elsif cli_options[:quiet]
          Vcloud::Core.logger.level = Logger::ERROR
        else
          Vcloud::Core.logger.level = Logger::INFO
        end
      end

    end
  end
end
