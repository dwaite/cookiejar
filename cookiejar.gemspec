# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cookiejar/version'

Gem::Specification.new do |s|
  s.name        = "cookiejar"
  s.version     = CookieJar::VERSION
  s.authors     = ["David Waite"]
  s.email       = ["david@alkaline-solutions.com"]
  s.description = %q{Allows for parsing and returning cookies in Ruby HTTP client code}
  s.summary     = %q{Client-side HTTP Cookie library}
  s.homepage    = %q{http://alkaline-solutions.com}
  s.date        = %q{2014-02-01}

  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^(spec)/})
  s.rdoc_options  = ["--title", "CookieJar -- Client-side HTTP Cookies"]
  s.require_paths = ["lib"]


  s.add_development_dependency 'yard'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'json'

end
