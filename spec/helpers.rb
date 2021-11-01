module Helpers
  def dbconfig
    {
      adapter: 'postgresql',
      password: 'postgres',
      host: 'localhost',
    }
  end

  def establish_connection(as:, to: :app, pool: 5)
    database = case to
               when :system
                 'postgres'
               when :app
                 'activerecord_tenant_level_security_test'
               else
                  raise "Unexpected value for 'to': #{to}"
               end

    username = case as
               when :superuser
                 'postgres'
               when :app
                 'activerecord_tenant_level_security_test'
               else
                 raise "Unexpected value for 'as': #{as}"
               end

    ActiveRecord::Base.establish_connection(dbconfig.merge(database: database, username: username, pool: pool))
  end

  def recreate_test_database
    ActiveRecord::Base.connection.recreate_database('activerecord_tenant_level_security_test')
  end

  def create_app_role
    begin
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE ROLE activerecord_tenant_level_security_test LOGIN;
      SQL
    rescue ActiveRecord::StatementInvalid => exn
      raise unless exn.cause.is_a?(PG::DuplicateObject)
      puts "Role 'activerecord_tenant_level_security_test' already exists"
    end
  end

  def grant_all_tables_to_app_role
    ActiveRecord::Base.connection.execute(<<~SQL)
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO activerecord_tenant_level_security_test
    SQL
  end

  module_function :dbconfig, :establish_connection, :recreate_test_database, :create_app_role, :grant_all_tables_to_app_role
end
