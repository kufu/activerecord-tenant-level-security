require 'active_support'
require 'active_record'
require 'pg'

require_relative 'activerecord-tenant-level-security/tenant_level_security'
require_relative 'activerecord-tenant-level-security/migration_extensions'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.include TenantLevelSecurity::MigrationExtensions
end
