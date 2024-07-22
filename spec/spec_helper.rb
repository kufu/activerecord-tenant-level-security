require "activerecord-tenant-level-security"
require "./spec/helpers"

# Avoid to raise "uninitialized class variable @@block" error when checking out the first connection
TenantLevelSecurity.current_tenant_id {}

Helpers.establish_connection(to: :system, as: :superuser)
Helpers.create_app_role
Helpers.recreate_test_database

Helpers.establish_connection(to: :app, as: :superuser)
require 'schema'
Helpers.grant_all_tables_to_app_role

if ENV['SQL_TO_STDOUT']
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

RSpec.configure do |config|
  config.include Helpers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) do
    # Reset current_tenant_id to avoid confused ConnectionTimeoutError.
    # For example, if you make a database query within this block,
    # it can cause an error because this block will be invoked when checking out a connection.
    TenantLevelSecurity.current_tenant_id {}

    # Reconnect as a superuser to delete/create fixtures
    establish_connection(as: :superuser)

    # Delete all fixtures
    Employee.delete_all
    Tenant.delete_all
    UUIDEmployee.delete_all
    UUIDTenant.delete_all
    Company.delete_all
    CompanyEmployee.delete_all
  end
end
