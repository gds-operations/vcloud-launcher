module Vcloud
  module Launcher
    module Schema

      LAUNCHER_VAPPS = {
        type: 'hash',
        allowed_empty: false,
        permit_unknown_parameters: true,
        internals: {
          vapps: {
            type: 'array',
            required: false,
            allowed_empty: true,
            each_element_is: Vcloud::Launcher::Schema::VAPP,
          },
        },
      }

    end
  end
end
