RSpec.describe TenantLevelSecurity do
  let(:tenant1) { Tenant.create!(name: 'Tenant1') }
  let(:tenant2) { Tenant.create!(name: 'Tenant2') }
  let(:uuid_tenant1) { UUIDTenant.create!(name: 'Tenant3') }
  let(:uuid_tenant2) { UUIDTenant.create!(name: 'Tenant4') }
  let(:company1) { Company.create!(name: 'Company1') }
  let(:company2) { Company.create!(name: 'Company2') }

  before do
    Employee.create!(name: 'Jane', tenant: tenant1)
    Employee.create!(name: 'Tom', tenant: tenant2)
    UUIDEmployee.create!(name: 'Kenny', tenant: uuid_tenant1)
    UUIDEmployee.create!(name: 'Wendy', tenant: uuid_tenant2)
    CompanyEmployee.create!(name: 'Alice', company: company1)
    CompanyEmployee.create!(name: 'Bob', company: company2)
    CompanyTenant.create!(name: 'James', company: company1)
    CompanyTenant.create!(name: 'Durant', company: company2)
  end

  describe '.switch!' do
    context 'with integer tenant_id' do
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

    context 'with uuid tenant_id' do
      it 'returns only employees in the switched tenant' do
        expect(UUIDEmployee.count).to eq 2

        establish_connection(as: :app)

        # Nothing is allowed by default
        expect(UUIDEmployee.count).to eq 0

        TenantLevelSecurity.switch!(uuid_tenant1.id)
        expect(UUIDEmployee.all).to contain_exactly(have_attributes(name: 'Kenny'))

        TenantLevelSecurity.switch!(uuid_tenant2.id)
        expect(UUIDEmployee.all).to contain_exactly(have_attributes(name: 'Wendy'))
      end
    end

    context 'with company_id' do
      context 'on company_employees' do
        it 'returns only employees in the switched company' do
          expect(CompanyEmployee.count).to eq 2

          establish_connection(as: :app)

          # Nothing is allowed by default
          expect(CompanyEmployee.count).to eq 0

          TenantLevelSecurity.switch!(company1.id)
          expect(CompanyEmployee.all).to contain_exactly(have_attributes(name: 'Alice'))

          TenantLevelSecurity.switch!(company2.id)
          expect(CompanyEmployee.all).to contain_exactly(have_attributes(name: 'Bob'))
        end
      end

      context 'on company_tenants' do
        it 'returns only tenants in the switched company' do
          expect(CompanyTenant.count).to eq 2

          establish_connection(as: :app)

          # Nothing is allowed by default
          expect(CompanyTenant.count).to eq 0

          TenantLevelSecurity.switch!(company1.id)
          expect(CompanyTenant.all).to contain_exactly(have_attributes(name: 'James'))

          TenantLevelSecurity.switch!(company2.id)
          expect(CompanyTenant.all).to contain_exactly(have_attributes(name: 'Durant'))
        end
      end
    end

    context 'with query cache' do
      it 'clears query cache after switching' do
        establish_connection(as: :app)

        Employee.connection.enable_query_cache!

        TenantLevelSecurity.switch!(tenant1.id)
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))

        TenantLevelSecurity.switch!(tenant2.id)
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Tom'))
      end
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

    context 'with query cache' do
      it 'clears query cache after switching' do
        establish_connection(as: :app)

        Employee.connection.enable_query_cache!

        TenantLevelSecurity.switch!(tenant1.id)
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))

        TenantLevelSecurity.with(tenant2.id) do
          expect(Employee.all).to contain_exactly(have_attributes(name: 'Tom'))
        end

        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))
      end
    end
  end

  describe 'current_tenant_id and current_session_tenant_id' do
    let!(:tenant3) { Tenant.create!(name: 'Tenant3') }

    it 'returns current tenant id and default tenant id' do
      establish_connection(as: :app)

      expect(TenantLevelSecurity.current_session_tenant_id).to eq ''
      # Returns all active connections so that checkout occurs
      ActiveRecord::Base.connection_handler.clear_active_connections!

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
