module TenantLevelSecurity
  module CommandRecorder
    def create_policy(*args)
      record(:create_policy, args)
    end

    def remove_policy(*args)
      record(:remove_policy, args)
    end

    def invert_create_policy(args)
      [:remove_policy, args]
    end

    def invert_remove_policy(args)
      [:create_policy, args]
    end
  end
end
