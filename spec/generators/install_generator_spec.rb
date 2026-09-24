require "tmpdir"
require "rails/generators"
require "generators/tenant_level_security/install_generator"

RSpec.describe TenantLevelSecurity::Generators::InstallGenerator, type: :generators do
  around do |example|
    Dir.mktmpdir do |dir|
      @destination_root = dir
      example.run
    end
  end

  describe "run generator" do
    subject { described_class.start([], destination_root: @destination_root) }

    let(:path) { "config/initializers/tenant_level_security.rb" }

    it "generated initializer file" do
      subject
      expect(File.exist?(File.expand_path(path, @destination_root))).to be true
    end
  end
end
