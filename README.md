# activerecord-tenant-level-security

[![CircleCI](https://circleci.com/gh/kufu/activerecord-tenant-level-security/tree/master.svg?style=svg)](https://circleci.com/gh/kufu/activerecord-tenant-level-security/tree/master)
[![gem-version](https://img.shields.io/gem/v/activerecord-tenant-level-security.svg)](https://rubygems.org/gems/activerecord-tenant-level-security)
[![License](https://img.shields.io/github/license/kufu/activerecord-tenant-level-security.svg?color=blue)](https://github.com/kufu/activerecord-tenant-level-security/blob/master/LICENSE.txt)

An Active Record extension for Multitenancy with PostgreSQL Row Level Security.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-tenant-level-security'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-tenant-level-security

## Usage

The activerecord-tenant-level-security provides an API for applying [PostgreSQL Row Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) (RLS) as follows:

```ruby
Employee.pluck(:name) # => ["Jane", "Tom"]

# Switch a connection as non-superuser
ActiveRecord::Base.establish_connection(app_user_config)

TenantLevelSecurity.with(tenant1.id) do
  Employee.pluck(:name) # => ["Jane"]
end

TenantLevelSecurity.with(tenant2.id) do
  Employee.pluck(:name) # => ["Tom"]
end
```

To enable RLS, you need to create a policy on the table. You can use `create_policy` in a migration file:

```ruby
class CreateEmployee < ActiveRecord::Migration[6.0]
  def change
    create_table :employees do |t|
      t.integer :tenant_id
      t.string :name
    end

    create_policy :employees
  end
end
```

By default, this method uses the `tenant_id` column as the partition key.  
To create a policy using a custom column as the partition key, specify the `partition_key` option as shown below:

```ruby
class CreateEmployee < ActiveRecord::Migration[6.0]
  def change
    create_table :employees do |t|
      t.integer :company_id
      t.string :name
    end

    create_policy :employees, partition_key: 'company_id'
  end
end
```

When experimenting, be aware of the database user you are trying to connect with. The default user `postgres` has the `BYPASSRLS` attribute and therefore bypasses the RLS. You must create a user who does not have these privileges in order for your application to connect.

If you want to use this gem, you first need to register a callback which gets the current tenant. This callback is invoked when checking out a new connection from a connection pool. Create an initializer and tell how it should resolve the current tenant like the following:

```ruby
TenantLevelSecurity.current_tenant_id { RequestStore.store[:current_tenant_id] }
```

The above is an example of getting the current tenant stored using [RequestStore](https://github.com/steveklabnik/request_store). You are responsible for storing the current tenant, such as at the beginning of the request.

We strongly recommend using the [activerecord-multi-tenant](https://github.com/citusdata/activerecord-multi-tenant) for this config. activerecord-multi-tenant provides multi-tenant data isolation at the application layer by rewriting queries. On the other hand, this gem provides the isolation at the database layer by RLS. Multi-layered security is important.

```ruby
TenantLevelSecurity.current_tenant_id { MultiTenant.current_tenant_id }
```

Do not query the database in this callback. As mentioned above, this callback is invoked at checking out a connection, so it may be called recursively.

## How it works

The policy created by the activerecord-tenant-level-security is:

```sql
CREATE POLICY tenant_policy ON employees
  AS PERMISSIVE
  FOR ALL
  TO PUBLIC
  USING (tenant_id = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::integer)
  WITH CHECK (tenant_id = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::integer)
```

In the table in which the policy is created, only the rows that match the current setting of `tenant_level_security.tenant_id` can be referenced. This value is set by `TenantLevelSecurity.with` etc.

```ruby
# Set default tenant to "tenant2"
TenantLevelSecurity.current_tenant_id { tenant2.id }

TenantLevelSecurity.with(tenant1.id) do # => SET tenant_level_security.tenant_id = '1'
  Employee.pluck(:name)
end # => SET tenant_level_security.tenant_id TO DEFAULT

Thread.new {
  # Checkout a new connection in a thread
  Employee.connection # => SET tenant_level_security.tenant_id = '2'
}.join
```

In this way, sessions are used to determine the current tenant. Therefore, avoid using it with transaction pooling like PgBouncer.

## Sidekiq Integration

If you are using [Sidekiq](https://sidekiq.org/), The activerecord-tenant-level-security will provide [middlewares](https://github.com/mperham/sidekiq/wiki/Middleware):

```ruby
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add TenantLevelSecurity::Sidekiq::Middleware::Client
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add TenantLevelSecurity::Sidekiq::Middleware::Server
  end

  config.client_middleware do |chain|
    chain.add TenantLevelSecurity::Sidekiq::Middleware::Client
  end
end
```

The middleware propagates the current tenant to the job through the session. This allows RLS to be enabled even within workers.

## Multiple Databases

Active Record 6+ adds support for [multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html). Note that when using multiple databases with this gem, you need to explicitly switch when connecting other databases.

In multiple databases, Active Record creates a connection pool for each connection, but `TenantLevelSecurity.switch` only switches for the current connection.

## Testing with Rails Fixtures

When testing a Rails app with multiple tenants, you might have fixtures for different tenants that need loading into
your database. However, Row-Level Security (RLS) might block this because it restricts data access. In order to bypass
RLS for loading these fixtures, you need to use a special database configuration.

In your database configuration in `config/database.yml`, add a `bypass_rls` cd config. This must use a superuser
database account, which can load fixtures without RLS restrictions. Do not forget to set `database_tasks: false` to
prevent Rails from messing with your primary database during setup or teardown tasks.

```yml
# config/database.yml
test:
  primary:
    <<: *default
    database: ...
    username: non_super_user_without_bypass_rls
  bypass_rls:
    <<: *default
    database: ...
    database_tasks: false # So that the primary db is not re-created or dropped when running rake db:create or db:drop.
    username: postgres    # This user must have the superuser privileges.
```

Then in your test setup in `test/test_helper.rb`, make sure to use the `bypass_rls` configuration for loading fixtures.
This involves connecting to the database with superuser privileges before running tests, especially important for
parallel tests to ensure each test process works with the correct database instance.

```ruby
# test/test_helper.rb

# Set up the `test_setup` role so we can utilize the `bypass_rls` config:
ActiveRecord::Base.connects_to database: { test_setup: :bypass_rls }

class ActiveSupport::TestCase
  # When running the tests in parallel, Rails automatically updates the primary db config but not the configs with
  # the `database_tasks: false` option. We need to ensure that the `bypass_rls` config also points to the same db as
  # the `primary` config.
  parallelize_setup do |index|
    ActiveRecord::Base.configurations.configs_for(env_name: "test", include_hidden: true).each do |config|
      config._database = "#{config.database}-#{index}" unless config.database.end_with?("-#{index}")
    end
  end

  # Run setup_fixtures in the test setup to bypass RLS:
  def setup_fixtures
    ActiveRecord::Base.connected_to(role: :test_setup) { super }
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kufu/activerecord-tenant-level-security. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the activerecord-tenant-level-security project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kufu/activerecord-tenant-level-security/blob/master/CODE_OF_CONDUCT.md).
