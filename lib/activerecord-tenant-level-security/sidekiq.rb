module TenantLevelSecurity
  module Sidekiq
    module Middleware
      class Client
        def call(worker_class, job, queue, redis_pool)
          if TenantLevelSecurity.current_session_tenant_id.present?
            job['tenant_level_security'] ||= { id: TenantLevelSecurity.current_session_tenant_id }
          end

          yield
        end
      end

      class Server
        def call(worker, job, queue)
          if job.key?('tenant_level_security')
            TenantLevelSecurity.with(job['tenant_level_security']['id']) do
              yield
            end
          else
            yield
          end
        end
      end
    end
  end
end
