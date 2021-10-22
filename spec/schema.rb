ActiveRecord::Schema.define(version: 1) do
  create_table :tenants, force: true do |t|
    t.string :name
  end

  create_table :employees, force: true do |t|
    t.integer :tenant_id
    t.string :name
  end

  create_policy :employees
end

class Tenant < ActiveRecord::Base
  has_many :employees
end

class Employee < ActiveRecord::Base
  belongs_to :tenant
end
