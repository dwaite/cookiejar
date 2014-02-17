# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "cookiejar"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Waite"]
  s.date = "2014-02-16"
  s.license = "BSD-2-Clause"
  s.description = "Allows for parsing and returning cookies in Ruby HTTP client code"
  s.email = "david@alkaline-solutions.com"
  s.files = [
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "contributors.json",
    "lib/cookiejar/cookie.rb",
    "lib/cookiejar/cookie_validation.rb",
    "lib/cookiejar/jar.rb",
    "lib/cookiejar.rb",
    "spec/cookie_spec.rb",
    "spec/cookie_validation_spec.rb",
    "spec/jar_spec.rb"
  ]
  s.homepage = "https://alkaline-solutions.com"
  s.rdoc_options = ["--title", "CookieJar -- Client-side HTTP Cookies"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.10"
  s.summary = "Client-side HTTP Cookie library"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
  s.add_development_dependency "rake",  ">= 10"
  s.add_development_dependency "rspec", ">= 2.14"
  s.add_development_dependency "yard",  ">= 0.8.7"
end
