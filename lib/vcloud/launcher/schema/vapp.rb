module Vcloud
  module Launcher
    module Schema

      VAPP = {
        type: 'hash',
        required: true,
        allowed_empty: false,
        internals: {
          name:               { type: 'string', required: true, allowed_empty: false },
          vdc_name:           { type: 'string', required: true, allowed_empty: false },
          catalog:            { type: 'string', deprecated_by: 'catalog_name', allowed_empty: false },
          catalog_name:       { type: 'string', required: true, allowed_empty: false },
          catalog_item:       { type: 'string', deprecated_by: 'vapp_template_name', allowed_empty: false },
          vapp_template_name: { type: 'string', required: true, allowed_empty: false },
          custom_fields: {
            type: 'array',
            required: false,
            each_element_is: {
              type: 'hash',
              internals: {
                name:              { type: 'string',  required: true },
                value:             { type: 'string',  required: true },
                type:              { type: 'string',  required: false},
                password:          { type: 'boolean', required: false},
                user_configurable: { type: 'boolean', required: false},
              },
            },
          },
          vm:                 Vcloud::Launcher::Schema::VM,
        },
      }

    end
  end
end
