module TenantLevelSecurity
  class << self
    def current_tenant_id(&block)
      if block_given?
        @@block = block
      else
        @@block.call
      end
    end

    def with(tenant_id)
      old_tenant_id = current_session_tenant_id
      return yield if old_tenant_id == tenant_id
      begin
        switch! tenant_id
        yield
      ensure
        switch! old_tenant_id
      end
    end

    def switch!(tenant_id)
      switch_with_connection!(ActiveRecord::Base.connection, tenant_id)
    end

    def switch_with_connection!(conn, tenant_id)
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
