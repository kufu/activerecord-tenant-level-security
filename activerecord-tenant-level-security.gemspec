lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activerecord-tenant-level-security/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord-tenant-level-security"
  spec.version       = TenantLevelSecurity::VERSION
  spec.authors       = ["SmartHR"]
  spec.email         = ["dev@smarthr.co.jp"]

  spec.summary       = %q{An Active Record extension for Multitenancy with PostgreSQL Row Level Security}
  spec.description   = %q{An Active Record extension for Multitenancy with PostgreSQL Row Level Security}
  spec.homepage      = "https://github.com/kufu/activerecord-tenant-level-security"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kufu/activerecord-tenant-level-security"
  spec.metadata["changelog_uri"] = "https://github.com/kufu/activerecord-tenant-level-security/blob/v#{TenantLevelSecurity::VERSION}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "pg", ">= 1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "appraisal", "~> 2.4"
end
