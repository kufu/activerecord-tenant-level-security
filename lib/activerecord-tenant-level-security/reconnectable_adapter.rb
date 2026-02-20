module TenantLevelSecurity
  module ReconnectableAdapter
    def configure_connection
      super

      TenantLevelSecurity.switch_current_tenant_context!(self)
    end
  end
end
