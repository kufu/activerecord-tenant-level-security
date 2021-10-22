RSpec.describe TenantLevelSecurity do
  let(:tenant1) { Tenant.create!(name: 'Tenant1') }
  let(:tenant2) { Tenant.create!(name: 'Tenant2') }

  before do
    Employee.create!(name: 'Jane', tenant: tenant1)
    Employee.create!(name: 'Tom', tenant: tenant2)
  end

  describe '.switch!' do
    it 'returns only employees in the switched tenant' do
      expect(Employee.count).to eq 2

      establish_connection(as: :app)

      # Nothing is allowed by default
      expect(Employee.count).to eq 0

      TenantLevelSecurity.switch!(tenant1.id)
      expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))

      TenantLevelSecurity.switch!(tenant2.id)
      expect(Employee.all).to contain_exactly(have_attributes(name: 'Tom'))
    end
  end

  describe '.with' do
    it 'returns employees in the switched tenant only within the block' do
      establish_connection(as: :app)

      # Nothing is allowed by default
      expect(Employee.count).to eq 0

      TenantLevelSecurity.with(tenant1.id) do
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))
      end

      # Back to default
      expect(Employee.count).to eq 0

      TenantLevelSecurity.switch!(tenant1.id)
      expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))

      TenantLevelSecurity.with(tenant2.id) do
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Tom'))
      end

      # Back to tenant1
      expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))
    end
  end

  describe 'current_tenant_id and current_session_tenant_id' do
    let!(:tenant3) { Tenant.create!(name: 'Tenant3') }

    it 'returns current tenant id and default tenant id' do
      establish_connection(as: :app)

      expect(TenantLevelSecurity.current_session_tenant_id).to eq ''
      # Returns all active connections so that checkout occurs
      ActiveRecord::Base.clear_active_connections!

      # Set default tenant
      TenantLevelSecurity.current_tenant_id { tenant1.id }

      # The current_session_tenant_id is set to the default tenant by callback when checking out a connection
      expect(TenantLevelSecurity.current_tenant_id).to eq tenant1.id
      expect(TenantLevelSecurity.current_session_tenant_id).to eq tenant1.id.to_s

      TenantLevelSecurity.switch!(tenant2.id)

      # Note that the current_tenant_id is supposed to be passed from the outside and does not represent the current tenant switch state.
      expect(TenantLevelSecurity.current_tenant_id).to eq tenant1.id
      expect(TenantLevelSecurity.current_session_tenant_id).to eq tenant2.id.to_s

      TenantLevelSecurity.with(tenant3.id) do
        expect(TenantLevelSecurity.current_tenant_id).to eq tenant1.id
        expect(TenantLevelSecurity.current_session_tenant_id).to eq tenant3.id.to_s
      end

      expect(TenantLevelSecurity.current_tenant_id).to eq tenant1.id
      expect(TenantLevelSecurity.current_session_tenant_id).to eq tenant2.id.to_s
    end
  end
end
