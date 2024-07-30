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
      # This error can occur if the specification of the 'tenant_policy' in PostgreSQL
      #   or the 'create_policy' method changes
      raise "Failed to parse partition key from 'qual': #{qual}" unless matched

      matched[1]
    end

    class Policy
      def initialize(table_name:, partition_key:)
        @table_name = table_name
        @partition_key = partition_key
      end

      def to_schema
        schema = %(  create_policy "#{table_name}")
        if partition_key && partition_key != TenantLevelSecurity::DEFAULT_PARTITION_KEY
          schema += %(, partition_key: "#{partition_key}")
        end
        schema
      end

      private

      attr_reader :table_name, :partition_key
    end
  end
end
