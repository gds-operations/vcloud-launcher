require 'optparse'

module Vcloud
  module Launcher
    class Cli

      def initialize(argv_array)
        @config_file = nil
        @usage_text = nil
        @options = {
          "vapp-name"         => false,
          "dont-power-on"     => false,
          "continue-on-error" => false,
          "quiet"             => false,
          "post-launch-cmd"   => false,
          "verbose"           => false,
        }

        parse(argv_array)
      end

      def run
        begin
          launch = Vcloud::Launcher::Launch.new(@config_file, @options)
          launch.run
        rescue => error_msg
          $stderr.puts(error_msg)
          exit 1
        end
      end

      private

      def parse(args)
        opt_parser = OptionParser.new do |opts|
          examples_dir = File.absolute_path(
            File.join(
              File.dirname(__FILE__),
              "..",
              "..",
              "..",
              "examples",
              File.basename($0),
            ))

          opts.banner = <<-EOS
Usage: #{$0} [options] config_file

vcloud-launch takes a configuration describing a vCloud Org,
and tries to make it a reality.

See https://github.com/gds-operations/vcloud-tools for more info

Example configuration files can be found in:
          #{examples_dir}
          EOS

          opts.separator ""
          opts.separator "Options:"

          opts.on('-n VAPP_NAME', '--vapp-name VAPP_NAME', 'Name of a single vApp to launch') do |vapp_name|
            @options['vapp-name'] = vapp_name
          end

          opts.on("-x", "--dont-power-on", "Do not power on vApps (default is to power on)") do
            @options["dont-power-on"] = true
          end

          opts.on("-c", "--continue-on-error", "Continue on error (default is false)") do
            @options["continue-on-error"] = true
          end

          opts.on("-q", "--quiet", "Quiet output - only report errors") do
            @options["quiet"] = true
          end

          opts.on("-p COMMAND", "--post-launch-cmd COMMAND", "Executable to run when a VM is successfully provisioned") do |command|
            if command.split().length() != 1
              exit_error_usage("COMMAND only accepts an executable name, not a command with arguments")
            else
              @options["post-launch-cmd"] = command
            end
          end

          opts.on("-v", "--verbose", "Verbose output") do
            @options["verbose"] = true
          end

          opts.on("-h", "--help", "Print usage and exit") do
            $stderr.puts opts
            exit
          end

          opts.on("--version", "Display version and exit") do
            puts Vcloud::Launcher::VERSION
            exit
          end
        end

        @usage_text = opt_parser.to_s
        begin
          opt_parser.parse!(args)
        rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
          exit_error_usage(e)
        end

        exit_error_usage("must supply config_file") unless args.size == 1
        @config_file = args.first
      end

      def exit_error_usage(error)
        $stderr.puts "#{$0}: #{error}"
        $stderr.puts @usage_text
        exit 2
      end
    end
  end
end
