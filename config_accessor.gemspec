# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "config_accessor/version"

Gem::Specification.new do |s|
  s.name        = "config_accessor"
  s.version     = ConfigAccessor::VERSION
  s.authors     = ["Alexei Mikhailov"]
  s.email       = ["amikhailov83@gmail.com"]
  s.homepage    = "https://github.com/take-five/config_accessor"
  s.summary     = %q{Class-level configurations}
  s.description = File.read(File.expand_path('../README.rdoc', __FILE__))

  s.rubyforge_project = "config_accessor"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
