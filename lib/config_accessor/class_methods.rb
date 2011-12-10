module ConfigAccessor
  module ClassMethods
    # config_accessor(symbol...) => nil
    #
    # Declare a named config attribute for this class
    # Allowed options:
    # * :transform - Symbol, Proc or Method that must be applied to configuration value before set
    # * :default - Default value for this config section
    # * :alias - alias name for configuration section
    def config_accessor(*names)
      # extract options
      options = names.last.is_a?(Hash) ? names.pop : {}

      # convert strings to symbols
      names.map!(&:to_sym)

      raise ArgumentError, 'config accessors names expected' unless names.length > 0

      raise ArgumentError, ':alias option should be set '\
                         'if and only if one argument supplied' if options.has_key?(:alias) &&
          names.length != 1

      names.each do |name|
        define_config_accessor(name, options)
      end

      nil
    end
    alias config_accessors config_accessor

    # Defines an instance and a singleton method with (optionally) alias.
    # The method parameter can be a <tt>Proc</tt>, a <tt>Method</tt> or an <tt>UnboundMethod</tt> object.
    def define_config_method(symbol, method, ali=nil)
      define_method(symbol, method)
      define_singleton_method(symbol, method)
      define_config_accessor_aliases(symbol, ali.to_sym) if ali
    end

    # Clone class-level configuration for each instance
    def new(*args, &block) #:nodoc:
      instance = super(*args, &block)

      # clone class-level variables
      defined_config_accessors.each do |name, val|
        instance.write_config_value(name, ConfigAccessor.try_duplicate(val))
      end

      instance
    end

    private
    # create universal config accessor
    def define_config_accessor(name, options) #:nodoc:
      transform = if t = options.delete(:transform)
                    raise TypeError, 'transformer must be Symbol, Method or Proc' unless t.respond_to?(:to_proc)
                    t.to_proc
                  end

      # create accessor
      accessor = proc do |*args, &block|
        if args.empty? && !block # reader
          read_config_value(name)
        else # writer
          raise ArgumentError, 'Too many arguments (%s for 1)' % args.length if args.length > 1

          val = args.first || block
          # apply :transform
          val = transform.call(val) if transform.is_a?(Proc)

          # set
          write_config_value(name, val)
        end
      end

      # set default value
      accessor.call(options.delete(:default)) if options.has_key?(:default)

      # add method
      define_config_method(name, accessor, options.delete(:alias))

      # return nil
      nil
    end

    # create alias for both singleton and instance methods
    def define_config_accessor_aliases(accessor_name, alias_name) #:nodoc:
      class_eval <<-CODE
      class << self
        alias #{alias_name} #{accessor_name}
      end
      alias #{alias_name} #{accessor_name}
      CODE
    end
  end
end