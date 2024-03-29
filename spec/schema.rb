ActiveRecord::Schema.define(version: 1) do
  enable_extension "pgcrypto"
  # Create tables for integer tenant_id
  create_table :tenants, force: true do |t|
    t.string :name
  end

  create_table :employees, force: true do |t|
    t.integer :tenant_id
    t.string :name
  end

  create_policy :employees

  # Create tables for uuid tenant_id
  create_table :uuid_tenants, id: :uuid, force: true do |t|
    t.string :name
  end

  create_table :uuid_employees, force: true do |t|
    t.uuid :tenant_id
    t.string :name
  end

  create_policy :uuid_employees
end

class Tenant < ActiveRecord::Base
  has_many :employees
end

class Employee < ActiveRecord::Base
  belongs_to :tenant
end

class UUIDTenant < ActiveRecord::Base
  has_many :employees, class_name: 'UUIDEmployee', foreign_key: :tenant_id
end

class UUIDEmployee < ActiveRecord::Base
  belongs_to :tenant, class_name: 'UUIDTenant', foreign_key: :tenant_id
end
