require 'active_support'
require 'active_support/current_attributes'
require 'active_record'
require 'pg'

require_relative 'activerecord-tenant-level-security/tenant_level_security'
require_relative 'activerecord-tenant-level-security/command_recorder'
require_relative 'activerecord-tenant-level-security/schema_dumper'
require_relative 'activerecord-tenant-level-security/schema_statements'
require_relative 'activerecord-tenant-level-security/sidekiq'
require_relative 'activerecord-tenant-level-security/reconnectable_adapter'

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters::AbstractAdapter.include TenantLevelSecurity::SchemaStatements
  ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend TenantLevelSecurity::ReconnectableAdapter
  ActiveRecord::Migration::CommandRecorder.include TenantLevelSecurity::CommandRecorder
  ActiveRecord::SchemaDumper.prepend TenantLevelSecurity::SchemaDumper

  # Set the callback so that a session will be set to the current tenant when a connection is reused.
  # Make sure that TenantLevelSecurity.current_tenant_id does not depend on database connections.
  # If a new connection is needed to get the current_tenant_id, the callback may be invoked recursively.
  ActiveRecord::ConnectionAdapters::AbstractAdapter.set_callback :checkout, :after do |conn|
    TenantLevelSecurity.switch_current_tenant_context!(conn)
  end
end
