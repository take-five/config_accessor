require "config_accessor/version"

module ConfigAccessor
  module Configure
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
    super(*args, &block).tap do |instance|
      # clone class-level variables
      defined_config_accessors.each do |name, val|
        instance.write_config_value(name, ConfigAccessor.try_duplicate(val))
      end
    end
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

  def try_duplicate(obj) #:nodoc:
    duplicable = [NilClass, TrueClass, FalseClass, Numeric, Symbol, Class, Module].none? { |klass| obj.is_a?(klass) }

    duplicable ? obj.dup : obj
  end
  public :try_duplicate
  module_function :try_duplicate
end

Object.extend(ConfigAccessor)
Object.extend(ConfigAccessor::Configure)
Object.send(:include, ConfigAccessor::Configure)