module TenantLevelSecurity
  DEFAULT_PARTITION_KEY = 'tenant_id'.freeze

  class TenantContext < ActiveSupport::CurrentAttributes
    attribute :tenant_id

    def tenant_id=(val)
      super
      TenantLevelSecurity.switch_with_connection!(ActiveRecord::Base.connection, val)
    end

    resets do
      TenantLevelSecurity.switch_with_connection!(ActiveRecord::Base.connection, nil)
    end
  end

  class << self
    # The current_tenant_id sets the default tenant from the outside.
    # Be sure to register in advance as `TenantLevelSecurity.current_tenant_id { id }` with initializers.
    # This value is mainly used as the current value when reusing a connection.
    # Therefore, keep in mind that you need to manage it differently from the session value in the database.
    def current_tenant_id(&block)
      if block_given?
        @@block = block
      else
        @@block.call
      end
    end

    def with(tenant_id, &block)
      TenantContext.with(tenant_id: tenant_id, &block)
    end

    def switch!(tenant_id)
      TenantContext.tenant_id = tenant_id
    end

    def switch_current_tenant_context!(conn = ActiveRecord::Base.connection)
      TenantLevelSecurity.switch_with_connection!(
        conn,
        TenantLevelSecurity::TenantContext.tenant_id || TenantLevelSecurity.current_tenant_id
      )
    end

    def switch_with_connection!(conn, tenant_id)
      conn.clear_query_cache

      if tenant_id.present?
        conn.execute("SET tenant_level_security.tenant_id = '#{tenant_id}'")
      else
        conn.execute('SET tenant_level_security.tenant_id TO DEFAULT')
      end
    end

    def current_session_tenant_id
      ActiveRecord::Base.connection.execute('SHOW tenant_level_security.tenant_id').getvalue(0, 0)
    rescue ActiveRecord::StatementInvalid => e
      return nil if e.cause.kind_of? PG::UndefinedObject
      raise
    end
  end
end
