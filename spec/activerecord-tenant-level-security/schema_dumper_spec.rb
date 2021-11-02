RSpec.describe TenantLevelSecurity::SchemaDumper do
  describe "ActiveRecord::SchemaDumper" do
    describe ".dump" do
      let(:definition) do
        io = StringIO.new
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, io)
        io.rewind

        io.read
      end

      it "outputs create_policy lines" do
        expect(definition).to be_include("create_policy")
      end
    end
  end
end
