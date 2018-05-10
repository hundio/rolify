module Rolify
  module Utils
    def self.extended(base)
      base.include(InstanceUtils)
    end
    
    def deprecate(old_method, new_method)
      define_method(old_method) do |*args|
        warn "[DEPRECATION] #{caller.first}: `#{old_method}` is deprecated.  Please use `#{new_method}` instead."
        send(new_method, *args)
      end
    end
    
    module InstanceUtils
      def role_identifier(role)
        if role.is_a?(Symbol) || role.is_a?(String)
          return :name, role.to_s
        elsif role.is_a? BSON::ObjectId
          return :id, role
        else
          return :id, role.id
        end
      end
    end
  end
end