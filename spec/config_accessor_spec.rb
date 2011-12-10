require File.expand_path('../test_helper', __FILE__)

describe ConfigAccessor do
  it "should be configurable" do
    c = Class.new {
      configurable!

      config_accessor :a
    }
    c.should respond_to(:a)
    c.new.should respond_to(:a)

    c.new.should_not respond_to(:config_accessor)
  end

  it "should be configurable in subclasses" do
    c = Class.new {
      configurable!

      config_accessor :a
    }
    d = Class.new(c) {}

    d.should respond_to(:a)
    d.new.should respond_to(:a)
  end

  it "should be able to set configuration values" do
    c = Class.new {
      configurable!

      config_accessor :port
      port 80
    }
    d = Class.new(c) {}
    instance = c.new

    c.port.should eq(80)
    instance.port.should eq(80)
    d.port.should eq(80)

    instance.port 81
    d.port.should eq(80)
  end

  it "should not mutate class configuration through instance" do
    c = Class.new {
      configurable!

      config_accessor :port, :ary
      port 80
      ary []
    }
    instance = c.new

    instance.port 81
    instance.ary << 1

    instance.port.should eq(81)
    instance.ary.should eq([1])

    c.port.should eq(80)
    c.ary.should eq([])

    c.port 82
    instance.port.should eq(81)
  end

  it "should be able to set default values" do
    c = Class.new {
      configurable!

      config_accessor :port, :default => 80
    }
    c.port.should eq(80)
  end

  it "should be able to define aliases" do
    c = Class.new {
      configurable!

      config_accessor :port, :alias => :inferred_port, :default => 80
    }
    c.inferred_port.should eq(80)
  end

  it "should accept blocks as values" do
    c = Class.new {
      configurable!

      config_accessor :transformer
      transformer { 22 }
    }
    c.transformer.should be_a_kind_of(Proc)
  end

  it "should transform values" do
    c = Class.new {
      configurable!

      config_accessor :port, :transform => :to_i
    }
    c.port "80"
    c.port.should eq(80)
  end
end