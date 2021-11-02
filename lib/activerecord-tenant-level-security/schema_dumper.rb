# frozen_string_literal: true

module TenantLevelSecurity
  module SchemaDumper
    def tables(stream)
      super
      policies(stream)
    end

    def policies(stream)
      # Section Separator
      stream.puts if policies_in_database.any?

      policies_in_database.each do |policy|
        stream.puts(policy.to_schema)
      end
    end

    def policies_in_database
      query = <<~SQL
        SELECT
          tablename
        FROM
          pg_policies
        WHERE
          policyname = 'tenant_policy'
        ORDER BY
          tablename;
      SQL
      results = ActiveRecord::Base.connection.execute(query)
      table_names = results.map { |x| x["tablename"] }

      table_names.map { |t| Policy.new(t) }
    end

    class Policy
      def initialize(table_name)
        @table_name = table_name
      end

      def to_schema
        %(  create_policy "#{table_name}")
      end

      private

      attr_reader :table_name
    end
  end
end
