RSpec.describe 'Connection Pool' do
  let(:tenant1) { Tenant.create!(name: 'Tenant1') }
  let(:tenant2) { Tenant.create!(name: 'Tenant2') }

  before do
    Employee.create!(name: 'Jane', tenant: tenant1)
    Employee.create!(name: 'Tom', tenant: tenant2)
  end

  def active_connections
    ActiveRecord::Base.connection_pool.connections.find_all(&:in_use?)
  end

  it 'returns only employees in the default tenant when reuse connections' do
    # Set default tenant
    TenantLevelSecurity.current_tenant_id { tenant2.id }

    establish_connection(as: :app, pool: 3)

    TenantLevelSecurity.switch!(tenant1.id)
    expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))

    2.times do
      Thread.new {
        TenantLevelSecurity.switch!(tenant1.id)
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Jane'))
      }.join
    end

    # Ensure all connections are used
    expect(active_connections.size).to eq 3

    2.times do
      Thread.new {
        expect(Employee.all).to contain_exactly(have_attributes(name: 'Tom'))
      }.join
    end
  end
end
