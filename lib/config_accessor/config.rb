module ConfigAccessor
  class Config < Hash #:nodoc:
    attr_reader :transformers

    def initialize(parent)
      super()

      @transformers = parent.respond_to?(:transformers) ? parent.transformers.dup : {}

      parent.each_pair do |k, v|
        self[k] = try_duplicate(v)
      end
    end

    # Make a deep copy of Config
    def dup
      Config.new(self)
    end

    def register_transformer(name, proc)
      raise TypeError, 'transformer must be Symbol, Method or Proc' unless proc.respond_to?(:to_proc)

      @transformers[name.to_sym] = proc.to_proc
    end

    # indifferent access
    def [](key)
      super(key.to_sym)
    end

    # indifferent access
    def fetch(key)
      super(key.to_sym)
    end

    # indifferent access
    def []=(key, value)
      super(key.to_sym, value)
    end

    # uniform access
    #   c = Config.new
    #   c.port 80
    #   c.port # => 80
    def access(key, *args, &block)
      if args.empty? && !block
        self[key]
      else
        raise ArgumentError, 'Too many arguments (%s for 1)' % args.length if args.length > 1

        val = args.first || block
        val = @transformers[key.to_sym].call(val) if @transformers[key.to_sym].respond_to?(:call)

        self[key] = val
      end
    end
    alias method_missing access

    private
    def try_duplicate(obj) #:nodoc:
      duplicable = [NilClass, TrueClass, FalseClass, Numeric, Symbol, Class, Module].none? { |klass| obj.is_a?(klass) }

      duplicable ? obj.dup : obj
    end
  end
end