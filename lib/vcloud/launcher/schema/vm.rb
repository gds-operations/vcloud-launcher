module Vcloud
  module Launcher
    module Schema

      VM = {
        type: 'hash',
        required: false,
        allowed_empty: false,
        internals: {
          network_connections: {
            type: 'array',
            required: false,
            each_element_is: {
              type: 'hash',
              internals: {
                name: { type: 'string', required: true },
                ip_address: { type: 'ip_address', required: false },
              },
            },
          },
          storage_profile: { type: 'string', required: false },
          hardware_config: {
            type: 'hash',
            required: false,
            internals: {
              cpu: { type: 'string_or_number', required: false },
              memory: { type: 'string_or_number', required: false },
            },
          },
          extra_disks: {
            type: 'array',
            required: false,
            allowed_empty: false,
            each_element_is: {
              type: 'hash',
              internals: {
                name: { type: 'string', required: false },
                size: { type: 'string_or_number', required: false },
              },
            },
          },
          bootstrap:   {
            type: 'hash',
            required: false,
            allowed_empty: false,
            internals: {
              script_path: { type: 'string', required: false },
              script_post_processor: { type: 'string', required: false },
              vars: { type: 'hash', required: false, allowed_empty: true },
            },
          },
          metadata: {
            type: 'hash',
            required: false,
            allowed_empty: true,
          },
        },
      }

    end
  end
end
