require 'active_support'
require 'active_record'
require 'pg'

require_relative 'activerecord-tenant-level-security/tenant_level_security'
require_relative 'activerecord-tenant-level-security/migration_extensions'
require_relative 'activerecord-tenant-level-security/sidekiq'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.include TenantLevelSecurity::MigrationExtensions

  ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback :checkout, :after do |conn|
    TenantLevelSecurity.switch_with_connection!(conn, TenantLevelSecurity.current_tenant_id)
  end
end
