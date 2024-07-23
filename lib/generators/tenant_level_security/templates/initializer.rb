# Pass current tenant ID to `TenantLevelSecurity.current_tenant_id` block
# using ActiveSupport::CurrentAttributes, RequestStore, etc...
# TenantLevelSecurity.current_tenant_id { RequestStore.store[:current_tenant_id] }

# Uncomment this line if you using activerecord-multi-tenant gem.
# TenantLevelSecurity.current_tenant_id { MultiTenant.current_tenant_id }
