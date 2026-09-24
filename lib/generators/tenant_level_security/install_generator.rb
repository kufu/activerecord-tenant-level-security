module TenantLevelSecurity
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/tenant_level_security.rb"
      end
    end
  end
end
