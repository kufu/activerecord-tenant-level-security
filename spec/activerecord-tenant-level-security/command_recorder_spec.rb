RSpec.describe TenantLevelSecurity::CommandRecorder do
  let(:recorder) { ActiveRecord::Migration::CommandRecorder.new }

  describe "#create_poilcy" do
    it "records create_policy" do
      recorder.create_policy(:accounts)

      expect(recorder.commands).to eq([[:create_policy, [:accounts], nil]])
    end

    it "reverts create_policy" do
      recorder.revert { recorder.create_policy(:accounts) }

      expect(recorder.commands).to eq([[:remove_policy, [:accounts]]])
    end
  end

  describe "#remove_policy" do
    it "records remove_policy" do
      recorder.remove_policy(:accounts)

      expect(recorder.commands).to eq([[:remove_policy, [:accounts], nil]])
    end

    it "reverts remove_policy" do
      recorder.revert { recorder.remove_policy(:accounts) }

      expect(recorder.commands).to eq([[:create_policy, [:accounts]]])
    end
  end
end
