# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{cookiejar}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Waite"]
  s.date = %q{2010-06-12}
  s.description = %q{Allows for parsing and returning cookies in Ruby HTTP client code}
  s.email = %q{david@alkaline-solutions.com}
  s.files = [
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "contributors.yaml",
    "lib/cookiejar/cookie.rb",
    "lib/cookiejar/cookie_validation.rb",
    "lib/cookiejar/jar.rb",
    "lib/cookiejar.rb",
    "test/cookie_test.rb",
    "test/cookie_validation_test.rb",
    "test/jar_test.rb"
  ]
  s.homepage = %q{http://alkaline-solutions.com}
  s.rdoc_options = ["--title", "CookieJar -- Client-side HTTP Cookies"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Client-side HTTP Cookie library}
  s.license = "GPL"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
