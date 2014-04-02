require 'vcloud/fog'
require 'vcloud/core'

require 'vcloud/launcher/launch'
require 'vcloud/launcher/vm_orchestrator'
require 'vcloud/launcher/vapp_orchestrator'

require 'vcloud/launcher/version'

module Vcloud
  module Launcher

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.clone_object object
      Marshal.load(Marshal.dump(object))
    end

  end
end
