module TenantLevelSecurity
  module SchemaStatements
    def create_policy(table_name, partition_key: TenantLevelSecurity::DEFAULT_PARTITION_KEY)
      quoted_table_name = quote_table_name(table_name)
      quoted_partition_key = quote_column_name(partition_key)
      execute <<~SQL
        ALTER TABLE #{quoted_table_name} ENABLE ROW LEVEL SECURITY;
        ALTER TABLE #{quoted_table_name} FORCE ROW LEVEL SECURITY;
      SQL
      tenant_id_data_type = get_tenant_id_data_type(table_name, partition_key)
      execute <<~SQL
        CREATE POLICY tenant_policy ON #{quoted_table_name}
          AS PERMISSIVE
          FOR ALL
          TO PUBLIC
          USING (#{quoted_partition_key} = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::#{tenant_id_data_type})
          WITH CHECK (#{quoted_partition_key} = NULLIF(current_setting('tenant_level_security.tenant_id'), '')::#{tenant_id_data_type})
      SQL
    end

    def remove_policy(table_name, *args)
      quoted_table_name = quote_table_name(table_name)
      execute <<~SQL
        ALTER TABLE #{quoted_table_name} NO FORCE ROW LEVEL SECURITY;
        ALTER TABLE #{quoted_table_name} DISABLE ROW LEVEL SECURITY;
      SQL
      execute <<~SQL
        DROP POLICY tenant_policy ON #{quoted_table_name}
      SQL
    end

    private
    def get_tenant_id_data_type(table_name, partition_key)
      tenant_id_column = columns(table_name).find { |column| column.name == partition_key.to_s }
      raise "#{partition_key} column is missing in #{table_name}" if tenant_id_column.nil?

      tenant_id_column.sql_type
    end
  end
end
