module TenantLevelSecurity
  module SchemaStatements
    def create_policy(table_name)
      execute <<~SQL
        ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{table_name} FORCE ROW LEVEL SECURITY;
      SQL
      tenant_id_data_type = get_tenant_id_data_type(table_name)
      execute <<~SQL
        CREATE POLICY tenant_policy ON #{table_name}
          AS PERMISSIVE
          FOR ALL
          TO PUBLIC
          USING (tenant_id = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::#{tenant_id_data_type})
          WITH CHECK (tenant_id = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::#{tenant_id_data_type})
      SQL
    end

    def remove_policy(table_name)
      execute <<~SQL
        ALTER TABLE #{table_name} NO FORCE ROW LEVEL SECURITY;
        ALTER TABLE #{table_name} DISABLE ROW LEVEL SECURITY;
      SQL
      execute <<~SQL
        DROP POLICY tenant_policy ON #{table_name}
      SQL
    end

    private
    def get_tenant_id_data_type(table_name)
      tenant_id_column = columns(table_name)
        .find{|column| column.name == 'tenant_id'}
      raise "tenant_id column is missing in #{table_name}" if tenant_id_column.nil?

      tenant_id_column.sql_type
    end
  end
end
