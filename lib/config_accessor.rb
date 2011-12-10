require "config_accessor/version"
require "config_accessor/config"
require "config_accessor/class_methods"
require "config_accessor/instance_methods"

module ConfigAccessor
  def configurable
    extend(ClassMethods)
    
    extend(InstanceMethods)
    include(InstanceMethods)
  end
  alias configurable! configurable

  def try_duplicate(obj) #:nodoc:
    duplicable = [NilClass, TrueClass, FalseClass, Numeric, Symbol, Class, Module].none? { |klass| obj.is_a?(klass) }

    duplicable ? obj.dup : obj
  end
  module_function :try_duplicate
end

Object.extend(ConfigAccessor)