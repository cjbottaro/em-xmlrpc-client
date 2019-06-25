# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-xmlrpc-client/version"

Gem::Specification.new do |s|
  s.name        = "em-xmlrpc-client"
  s.version     = Em::Xmlrpc::Client::VERSION
  s.authors     = ["Christopher J. Bottaro"]
  s.email       = ["cjbottaro@alumni.cs.utexas.edu"]
  s.homepage    = "https://github.com/cjbottaro/em-xmlrpc-client"
  s.summary     = %q{Evented and fibered XMLRPC Client}
  s.description = %q{Monkey patches Ruby's standard XMLRPC Client to use EventMachine and fibers}

  s.rubyforge_project = "em-xmlrpc-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "em-http-request", "~> 1.0"

  # specify any dependencies here; for example:
  s.add_development_dependency "eventmachine"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rr"

  # s.add_runtime_dependency "rest-client"
end
