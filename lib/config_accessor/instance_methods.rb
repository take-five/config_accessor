module ConfigAccessor
  # Both instance and class-level methods
  module InstanceMethods
    def configure(&block)
      raise ArgumentError, 'Block expected' unless block_given?

      self.instance_eval(&block)

      self
    end

    # Writes names configuration value
    def write_config_value(name, value)
      (@_config_accessors ||= {})[name.to_sym] = value
    end

    # Reads configuration value (supports inheritance)
    def read_config_value(name)
      parent_config_accessors.merge(@_config_accessors || {})[name.to_sym]
    end

    protected
    # inheritable config accessors array
    def defined_config_accessors #:nodoc:
      @_config_accessors ||= {}
    end

    def parent_config_accessors #:nodoc:
      superklass = (self.is_a?(Class) ? self : self.class).superclass
      superklass.respond_to?(:defined_config_accessors) ? superklass.defined_config_accessors : {}
    end
  end
end