module Vcloud
  module Launcher
    class Preamble
      class MissingConfigurationError < StandardError ; end
      class MissingTemplateError < StandardError ; end

      attr_reader :preamble_vars, :script_path

      def initialize(vapp_name, vm_config)
        @vapp_name        = vapp_name
        bootstrap_config  = vm_config[:bootstrap_config]

        raise MissingConfigurationError if bootstrap_config.nil?

        @script_path = bootstrap_config.fetch(:script_path, nil)
        raise MissingTemplateError unless @script_path

        # Missing vars is acceptable - noop template.
        @preamble_vars = bootstrap_config.fetch(:vars, {})
        extra_disks    = vm_config.fetch(:extra_disks, {})

        raise MissingConfigurationError, "Missing vars" if @preamble_vars.empty?

        @preamble_vars.merge!(extra_disks: extra_disks)

        @script_post_processor = bootstrap_config.fetch(:script_post_processor, nil)
      end

      def generate
        @script_post_processor ? post_process_erb_output : interpolated_preamble
      end

      def interpolated_preamble
        @interpolated_preamble = interpolate_erb_file
      end

      private

      def interpolate_erb_file
        erb_vars = OpenStruct.new({
          vapp_name: @vapp_name,
          vars:      @preamble_vars,
        })
        binding_object  = erb_vars.instance_eval { binding }
        template_string = load_erb_file

        ERB.new(template_string, nil, '>-').result(binding_object)
      end

      def load_erb_file
        File.read(File.expand_path(@script_path))
      end

      def post_process_erb_output
        # Open3.capture2, as we just need to return STDOUT of the post_processor_script
        Open3.capture2(
          File.expand_path(@script_post_processor),
          stdin_data: interpolated_preamble).first
      end
    end
  end
end
