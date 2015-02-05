module Vcloud
  module Launcher
    class Launch

      class MissingPreambleError < RuntimeError ; end
      class MissingConfigurationError < RuntimeError ; end

      attr_reader :config, :options

      def initialize(config_file, options = {})
        config_loader = ::Vcloud::Core::ConfigLoader.new
        @options = options

        set_logging_level
        @config = config_loader.load_config(config_file, Vcloud::Launcher::Schema::LAUNCHER_VAPPS)

        validate_config
      end

      def run
        @config[:vapps].each do |vapp_config|
          Vcloud::Core.logger.info("Provisioning vApp #{vapp_config[:name]}.")
          begin
            vapp = ::Vcloud::Launcher::VappOrchestrator.provision(vapp_config)

            vapp.power_on if options[:power_on]
            if options["post-launch-cmd"]
              run_command(vapp_config, options["post-launch-cmd"])
            end

            Vcloud::Core.logger.info("Provisioned vApp #{vapp_config[:name]} successfully.")
          rescue RuntimeError => e
            Vcloud::Core.logger.error("Failure: Could not provision vApp: #{e.message}")
            break unless options[:continue_on_error]
          end

        end
      end

      private

      def run_command(vapp_definition, command)
        command_path = File.expand_path(command)
        if File.exist?(command_path)
          begin
            Vcloud::Core.logger.info("Running #{command_path} for #{vapp_definition[:name]}")
            ENV['VAPP_DEFINITION'] = vapp_definition.to_s
            exit_status = system(command_path)
            exit_message = $?
            if exit_status == false
              # The command has returned a non-zero exit code
              Vcloud::Core.logger.error("Failed to run #{command_path} for #{vapp_definition[:name]} exited with a non-zero response: #{exit_message}")
            elsif exit_status == nil
              # The call to system() has returned no exit code
              Vcloud::Core.logger.error("Failed to run #{command_path} for #{vapp_definition[:name]} could not be run: #{exit_message}")
            else
              # The command has returned a zero exit code SUCCESS!
              Vcloud::Core.logger.debug("Ran #{command_path} with VAPP_DEFINITION=#{vapp_definition}")
            end
          rescue
            # Catch various errors including no permissions or unable to execute script
            Vcloud::Core.logger.error("Failed to run #{command_path} for #{vapp_definition[:name]}")
          end
        else
          # Catch specific case of a script that does not exist
          Vcloud::Core.logger.error("#{command_path} does not exist")
        end
      end

      def set_logging_level
        if options[:verbose]
          Vcloud::Core.logger.level = Logger::DEBUG
        elsif options[:quiet]
          Vcloud::Core.logger.level = Logger::ERROR
        else
          Vcloud::Core.logger.level = Logger::INFO
        end
      end

      def validate_config
        @config[:vapps].each do |vapp_config|
          validate_vapp_config(vapp_config)
        end
      end

      def validate_vapp_config(vapp_config)
        bootstrap_config = vapp_config.fetch(:bootstrap, nil)

        return unless bootstrap_config

        if ! bootstrap_config[:script_path]
          raise MissingConfigurationError, "Preamble script (script_path) not specified"
        end

        if bootstrap_config[:script_path] && ! File.exist?( bootstrap_config[:script_path])
          raise MissingPreambleError, "Unable to find specified preamble script (#{bootstrap_config[:script_path]})"
        end

        template_vars = bootstrap_config.fetch(:vars, {})

        if bootstrap_config[:script_path] && template_vars.empty?
          Vcloud::Core.logger.info("Preamble file/template specified without variables to template.")
        end
      end
    end
  end
end
