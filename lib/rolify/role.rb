require "rolify/finders"
require "rolify/utils"

module Rolify
  module Role
    extend Utils

    def self.included(base)
      base.extend Finders
    end

    def add_role(role, resource = nil)
      identifier, role = role_identifier role
      role = case identifier
      when :name
        self.class.adapter.find_or_create_by({ identifier => role },
                                          (resource.is_a?(Class) ? resource.to_s : resource.class.name if resource),
                                          (resource.id if resource && !resource.is_a?(Class)))
      when :id
        self.class.adapter.find_or_create_by identifier => role
      when :itself
        role.save
        role
      end

      if !roles.include?(role)
        self.class.define_dynamic_method(role.name, resource) if Rolify.dynamic_shortcuts
        self.class.adapter.add(self, role)
      end
      role
    end
    alias_method :grant, :add_role

    def has_role?(role, resource = nil)
      return has_strict_role?(role, resource) if self.class.strict_rolify and resource and resource != :any
      identifier, role = role_identifier role
      
      if new_record?
        self.roles.any? { |r|
          r.send(identifier) == role &&
            (identifier != :name || (r.resource == resource ||
             resource.nil? ||
             (resource == :any && r.resource.present?)))
        }
      else
        case identifier
        when :name
          self.class.adapter.where(self.roles, identifier => role, resource: resource).exists?
        when :id
          self.class.adapter.where(self.roles, identifier => role).exists?
        when :itself
          self.roles.include? role
        end
      end
    end

    def has_strict_role?(role, resource)
      identifier, role = role_identifier role
      self.class.adapter.where_strict(self.roles, identifier => role, resource: resource).any?
    end

    def has_cached_role?(role_name, resource = nil)
      return has_strict_cached_role?(role_name, resource) if self.class.strict_rolify and resource and resource != :any
      self.class.adapter.find_cached(self.roles, name: role_name, resource: resource).any?
    end

    def has_strict_cached_role?(role_name, resource = nil)
      self.class.adapter.find_cached_strict(self.roles, name: role_name, resource: resource).any?
    end

    def has_all_roles?(*args)
      args.each do |arg|
        if arg.is_a? Hash
          return false if !self.has_role?(arg[:name], arg[:resource])
        else
          return false if !self.has_role?(arg)
        end
      end
      true
    end

    def has_any_role?(*args)
      if new_record?
        args.any? { |r| self.has_role?(r) }
      else
        queries = []
        args.each do |arg|
          if arg.is_a? Hash
            queries << arg
          else
            identifier, role = role_identifier arg
            return true if identifier == :itself && self.roles.include?(role)
            queries << { identifier => role }
          end
        end
        self.class.adapter.where(self.roles, *queries).size > 0
      end
    end

    def only_has_role?(role, resource = nil)
      return self.has_role?(role, resource) && self.roles.count == 1
    end

    def remove_role(role, resource = nil)
      identifier, role = role_identifier role
      if identifier == :itself
        role = role.id
        identifier = :id
      end
      self.class.adapter.remove(self, { identifier => role }, resource)
    end

    alias_method :revoke, :remove_role
    deprecate :has_no_role, :remove_role

    def roles_name
      self.roles.select(:name).map { |r| r.name }
    end

    def method_missing(method, *args, &block)
      if method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/)
        resource = args.first
        self.class.define_dynamic_method $1, resource
        return has_role?("#{$1}", resource)
      end if Rolify.dynamic_shortcuts
      super
    end

    def respond_to?(method, include_private = false)
      if Rolify.dynamic_shortcuts && (method.to_s.match(/^is_(\w+)_of[?]$/) || method.to_s.match(/^is_(\w+)[?]$/))
        query = self.class.role_class.where(:name => $1)
        query = self.class.adapter.exists?(query, :resource_type) if method.to_s.match(/^is_(\w+)_of[?]$/)
        return true if query.count > 0
        false
      else
        super
      end
    end
  end
end
