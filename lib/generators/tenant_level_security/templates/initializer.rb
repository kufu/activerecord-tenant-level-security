# Pass current tenant ID to `TenantLevelSecurity.current_tenant_id` block
# using ActiveSupport::CurrentAttributes, RequestStore, etc...
#
# The following example of using ActiveSupport::CurrentAttributes:
#
#   # app/models/current.rb
#   class Current < ActiveSupport::CurrentAttributes
#     attribute :current_tenant_id
#   end
#
# TenantLevelSecurity.current_tenant_id { Current.curent_tenant_id }

# Uncomment this line if you using activerecord-multi-tenant gem.
# TenantLevelSecurity.current_tenant_id { MultiTenant.current_tenant_id }
