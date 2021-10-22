module TenantLevelSecurity
  module SchemaStatements
    def create_policy(table_name)
      execute <<~SQL
        ALTER TABLE #{table_name} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{table_name} FORCE ROW LEVEL SECURITY;
      SQL
      execute <<~SQL
        CREATE POLICY tenant_policy ON #{table_name}
          AS PERMISSIVE
          FOR ALL
          TO PUBLIC
          USING (tenant_id::text = current_setting('tenant_level_security.tenant_id'))
          WITH CHECK (tenant_id::text = current_setting('tenant_level_security.tenant_id'))
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
  end
end
