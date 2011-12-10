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
    def define_config_method(symbol, ali=nil)
      class_eval <<-CODE
        class << self                           # class << self
          def #{symbol}(*args, &block)          #   def port(*args, &block)
            config.#{symbol}(*args, &block)     #     config.port(*args, &block)
          end                                   #   end
          alias #{symbol}= #{symbol}            #   alias port= port
          #{"alias #{ali} #{symbol}" if ali}    #   alias inferred_port port
          #{"alias #{ali}= #{symbol}" if ali}   #   alias inferred_port= port
        end                                     # end

        def #{symbol}(*args, &block)            # def port(*args, &block)
          config.#{symbol}(*args, &block)       #   config.port(*args, &block)
        end                                     # end
        alias #{symbol}= #{symbol}              # alias port= port
        #{"alias #{ali} #{symbol}" if ali}      # alias inferred_port port
        #{"alias #{ali}= #{symbol}" if ali}     # alias inferred_port= port
      CODE
    end

    private
    # create universal config accessor
    def define_config_accessor(name, options) #:nodoc:
      if t = options.delete(:transform)
        config.register_transformer(name, t)
      end

      # add method
      define_config_method(name, options.delete(:alias))

      # set default value
      send(name, options.delete(:default)) if options.has_key?(:default)

      # return nil
      nil
    end
  end
end