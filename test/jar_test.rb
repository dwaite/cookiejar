require 'cookiejar'
require 'yaml'

describe Jar do
  it "should allow me to set a cookie" do
    jar = Jar.new 
    jar.set_cookie 'http://foo.com/', 'foo=bar'
  end
  it "should allow me to set multiple cookies" do
    jar = Jar.new 
    jar.set_cookie 'http://foo.com/', 'foo=bar'
    jar.set_cookie 'http://foo.com/', 'bar=baz'
    jar.set_cookie 'http://auth.foo.com/', 'foo=bar'    
    puts jar.to_yaml
    assert false
  end
end