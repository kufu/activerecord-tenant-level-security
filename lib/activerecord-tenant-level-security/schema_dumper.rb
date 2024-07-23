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
          tablename,
          qual
        FROM
          pg_policies
        WHERE
          policyname = 'tenant_policy'
        ORDER BY
          tablename;
      SQL
      results = ActiveRecord::Base.connection.execute(query)
      results.map do |result|
        table_name = result["tablename"]
        partition_key = convert_qual_to_partition_key(result["qual"])
        Policy.new(table_name: table_name, partition_key: partition_key)
      end
    end

    private

    def convert_qual_to_partition_key(qual)
      matched = qual.match(/^\((.+?) = /)
      matched ? matched[1] : nil
    end

    class Policy
      DEFAULT_PARTITION_KEY = 'tenant_id'

      def initialize(table_name:, partition_key:)
        @table_name = table_name
        @partition_key = partition_key
      end

      def to_schema
        schema = %(  create_policy "#{table_name}")
        schema += %(, partition_key: "#{partition_key}") if partition_key && partition_key != DEFAULT_PARTITION_KEY
        schema
      end

      private

      attr_reader :table_name, :partition_key
    end
  end
end
