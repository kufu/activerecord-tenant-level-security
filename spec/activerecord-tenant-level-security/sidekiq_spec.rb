RSpec.describe 'Sidekiq' do
  let(:tenant1) { Tenant.create!(name: 'Tenant1') }
  let(:tenant2) { Tenant.create!(name: 'Tenant2') }

  before do
    Employee.create!(name: 'Jane', tenant: tenant1)
    Employee.create!(name: 'Tom', tenant: tenant2)
  end

  describe 'client middleware' do
    let(:client) { TenantLevelSecurity::Sidekiq::Middleware::Client.new }

    it 'passes the current tenant to the job message' do
      establish_connection(as: :app)
      TenantLevelSecurity.switch!(tenant1.id)

      job = {}
      client.call(double, job, 'default', double) do
        expect(job).to eq({ 'tenant_level_security' => { id: tenant1.id.to_s } })
      end
    end

    it 'does not pass tenant context when not switched' do
      establish_connection(as: :app)

      job = {}
      client.call(double, job, 'default', double) do
        expect(job).to be_empty
      end
    end

    it 'does not call current_session_tenant_id when tenant_level_security already exists in job' do
      establish_connection(as: :app)
      TenantLevelSecurity.switch!(tenant1.id)

      job = { 'tenant_level_security' => { id: tenant2.id.to_s } }
      expect(TenantLevelSecurity).not_to receive(:current_session_tenant_id)

      client.call(double, job, 'default', double) do
        # job should retain the original tenant_level_security value
        expect(job['tenant_level_security']).to eq({ id: tenant2.id.to_s })
      end
    end

    it 'does not overwrite existing tenant_level_security in job' do
      establish_connection(as: :app)
      TenantLevelSecurity.switch!(tenant1.id)

      original_tenant_data = { id: 'original-tenant-id' }
      job = { 'tenant_level_security' => original_tenant_data }

      client.call(double, job, 'default', double) do
        expect(job['tenant_level_security']).to eq(original_tenant_data)
      end
    end
  end

  describe 'server middleware' do
    let(:server) { TenantLevelSecurity::Sidekiq::Middleware::Server.new }

    it 'returns only employees in the tenant which provided in message' do
      establish_connection(as: :app)

      server.call(double, { 'tenant_level_security' => { 'id' => tenant1.id } }, 'default') do
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))
      end
    end

    it 'returns no employees when no message provided' do
      establish_connection(as: :app)

      server.call(double, { 'foo' => 'bar' }, 'default') do
        expect(Employee.count).to eq 0
      end
    end
  end
end
