module ConfigAccessor
  # Both instance and class-level methods
  module InstanceMethods
    # Sexy notation:
    #   class Tank
    #     config_accessor :target
    #   end
    #
    #   Tank.configure {
    #     target "localhost:80"
    #   }
    #
    # or (result is the same):
    #   Tank.configure do |conf|
    #     conf.target "localhost:80"
    #   end
    def configure(&block)
      raise ArgumentError, 'Block expected' unless block_given?

      if block.arity == 1
        yield(config)
      else
        config.instance_eval(&block)
      end
    end

    # Direct access to configuration values
    def config
      if self.is_a?(Class)
        @_config ||= ConfigAccessor::Config.new(parent_config)
      else
        @_config ||= self.class.config.dup
      end
    end

    protected
    def parent_config #:nodoc:
      superklass = (self.is_a?(Class) ? self : self.class).superclass
      superklass.respond_to?(:config) ? superklass.config : {}
    end
  end
end