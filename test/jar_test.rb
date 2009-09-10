require 'cookiejar'
require 'yaml'
include CookieJar

describe Jar do
  describe '.setCookie' do
    it "should allow me to set a cookie" do
      jar = Jar.new 
      jar.set_cookie 'http://foo.com/', 'foo=bar'
    end
    it "should allow me to set multiple cookies" do
      jar = Jar.new 
      jar.set_cookie 'http://foo.com/', 'foo=bar'
      jar.set_cookie 'http://foo.com/', 'bar=baz'
      jar.set_cookie 'http://auth.foo.com/', 'foo=bar'
      jar.set_cookie 'http://auth.foo.com/', 'auth=135121...;domain=foo.com'    
    end
  end
  describe '.get_cookies' do
    it "should let me read back cookies which are set" do
      jar = Jar.new 
      jar.set_cookie 'http://foo.com/', 'foo=bar'
      jar.set_cookie 'http://foo.com/', 'bar=baz'
      jar.set_cookie 'http://auth.foo.com/', 'foo=bar'
      jar.set_cookie 'http://auth.foo.com/', 'auth=135121...;domain=foo.com'
      jar.get_cookies('http://foo.com/').should have(3).items
    end
    it "should return cookies longest path first" do
      jar = Jar.new
      uri = 'http://foo.com/a/b/c/d' 
      jar.set_cookie uri, 'a=bar'
      jar.set_cookie uri, 'b=baz;path=/a/b/c/d'
      jar.set_cookie uri, 'c=bar;path=/a/b'
      jar.set_cookie uri, 'd=bar;path=/a/'
      cookies = jar.get_cookies(uri)
      cookies.should have(4).items
      cookies[0].name.should == 'b'
      cookies[1].name.should == 'a'
      cookies[2].name.should == 'c'
      cookies[3].name.should == 'd'
    end
    it "should not return expired cookies" do
      jar = Jar.new
      uri = 'http://localhost/'
      jar.set_cookie uri, 'foo=bar;expires=Wednesday, 09-Nov-99 23:12:40 GMT'
      cookies = jar.get_cookies(uri)
      cookies.should have(0).items
    end
  end
  describe '.get_cookie_headers' do
    it "should return cookie headers" do
      jar = Jar.new
      uri = 'http://foo.com/a/b/c/d' 
      jar.set_cookie uri, 'a=bar'
      jar.set_cookie uri, 'b=baz;path=/a/b/c/d'
      cookie_headers = jar.get_cookie_headers uri
      cookie_headers.should have(2).items
      cookie_headers.should == [['Cookie', 'b=baz'],['Cookie', 'a=bar']]
    end
  end
end