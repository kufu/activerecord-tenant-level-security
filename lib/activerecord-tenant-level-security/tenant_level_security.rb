module TenantLevelSecurity
  class << self
    def with(tenant_id)
      old_tenant_id = current_tenant_id
      begin
        switch! tenant_id
        yield
      ensure
        switch! old_tenant_id
      end
    end

    def without
      old_tenant_id = current_tenant_id
      begin
        disable!
        yield
      ensure
        switch! old_tenant_id
      end
    end

    def switch!(tenant_id)
      ActiveRecord::Base.connection.execute('SET tenant_level_security.disable TO DEFAULT')
      if tenant_id.present?
        ActiveRecord::Base.connection.execute("SET tenant_level_security.tenant_id = '#{tenant_id}'")
      else
        ActiveRecord::Base.connection.execute('SET tenant_level_security.tenant_id TO DEFAULT')
      end
    end

    def disable!
      ActiveRecord::Base.connection.execute('SET tenant_level_security.disable = true')
      ActiveRecord::Base.connection.execute('SET tenant_level_security.tenant_id TO DEFAULT')
    end

    def current_tenant_id
      ActiveRecord::Base.connection.execute('SHOW tenant_level_security.tenant_id').getvalue(0, 0)
    rescue ActiveRecord::StatementInvalid => e
      return nil if e.cause.kind_of? PG::UndefinedObject
      raise
    end
  end
end
