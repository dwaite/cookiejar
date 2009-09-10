require 'cookiejar'
require 'cookiejar/cookie_logic'
include CookieJar

describe CookieLogic do
  include CookieLogic
  
  describe ".effective_host" do
    it "should leave proper domains the same" do
      ['google.com', 'www.google.com', 'google.com.'].each do |value|
        effective_host(value).should == value
      end
    end
    it "should handle a URI object" do
      effective_host(URI.parse('http://example.com/')).should == 'example.com'
    end	
    it "should add a local suffix on unqualified hosts" do
      effective_host('localhost').should == 'localhost.local'
    end
    it "should leave IPv4 addresses alone" do
      effective_host('127.0.0.1').should == '127.0.0.1'
    end
    it "should leave IPv6 addresses alone" do
      ['2001:db8:85a3::8a2e:370:7334', ':ffff:192.0.2.128'].each do |value|
        effective_host(value).should == value
      end
    end
    it "should lowercase addresses" do
      effective_host('FOO.COM').should == 'foo.com'
    end
  end
  
  describe '.hostname_reach' do
    it "should find the next highest subdomain" do
      {'www.google.com' => 'google.com', 'auth.corp.companyx.com' => 'corp.companyx.com'}.each do |entry|
        hostname_reach(entry[0]).should == entry[1]
      end
    end
    it "should handle domains with suffixed dots" do
      hostname_reach('www.google.com.').should == 'google.com.'
    end
    it "should return nil for a root domain" do
      hostname_reach('github.com').should be_nil
    end
    it "should return 'local' for a local domain" do
      ['foo.local', 'foo.local.'].each do |hostname|
        hostname_reach(hostname).should == 'local'
      end
    end
    it "should return nil for an IPv4 address" do
      hostname_reach('127.0.0.1').should be_nil
    end
    it "should return nil for IPv6 addresses" do
      ['2001:db8:85a3::8a2e:370:7334', '::ffff:192.0.2.128'].each do |value|
        hostname_reach(value).should be_nil
      end
    end
  end

  describe '.cookie_base_path' do
    it "should leave '/' alone" do
      cookie_base_path('/').should == '/'
    end
    it "should strip off everything after the last '/'" do
      cookie_base_path('/foo/bar/baz').should == '/foo/bar/'
    end
    it "should handle query parameters and fragments with slashes" do
      cookie_base_path('/foo/bar?query=a/b/c#fragment/b/c').should == '/foo/'
    end
    it "should handle URI objects" do
      cookie_base_path(URI.parse('http://www.foo.com/bar/')).should == '/bar/'
    end
    it "should preserve case" do
      cookie_base_path("/BaR/").should == '/BaR/'
    end
  end
  
  describe '.determine_cookie_domain' do
    it "should add a dot to the front of domains" do
      determine_cookie_domain('http://foo.com/', 'foo.com').should == '.foo.com'
    end
    it "should not add a second dot if one present" do
      determine_cookie_domain('http://foo.com/', '.foo.com').should == '.foo.com'
    end
    it "should handle Cookie objects" do
      c = Cookie.from_set_cookie('http://foo.com/', "foo=bar;domain=foo.com")
      determine_cookie_domain('http://foo.com/', c).should == '.foo.com'
    end
    it "should handle URI objects" do
      determine_cookie_domain(URI.parse('http://foo.com/'), '.foo.com').should == '.foo.com'
    end
    it "should use an exact hostname when no domain specified" do
      determine_cookie_domain('http://foo.com/', '').should == 'foo.com'
    end
    it "should leave IPv4 addresses alone" do
      determine_cookie_domain('http://127.0.0.1/', '127.0.0.1').should == '127.0.0.1'
    end
    it "should leave IPv6 addresses alone" do
      ['2001:db8:85a3::8a2e:370:7334', '::ffff:192.0.2.128'].each do |value|
        determine_cookie_domain("http://[#{value}]/", value).should == value
      end
    end
  end
  describe '.determine_cookie_path' do
    it "should use the requested path when none is specified for the cookie" do
      determine_cookie_path('http://foo.com/', nil).should == '/'
      determine_cookie_path('http://foo.com/bar/baz', '').should == '/bar/'
    end
    it "should handle URI objects" do
      determine_cookie_path(URI.parse('http://foo.com/bar/'), '').should == '/bar/'
    end
    it "should handle Cookie objects" do
      cookie = Cookie.from_set_cookie('http://foo.com/', "name=value;path=/")
      determine_cookie_path('http://foo.com/', cookie).should == '/'
    end
    it "should ignore the request when a path is specified" do
      determine_cookie_path('http://foo.com/ignorable/path', '/path/').should == '/path/'
    end
  end
  describe '.domains_match' do
    it "should handle exact matches" do
      domains_match('foo', 'foo').should be_true
      domains_match('foo.com', 'foo.com').should be_true
      domains_match('127.0.0.1', '127.0.0.1').should be_true
      domains_match('::ffff:192.0.2.128', '::ffff:192.0.2.128').should be_true
    end
    it "should handle matching a superdomain" do
      domains_match('auth.foo.com', 'foo.com').should be_true
      domains_match('x.y.z.foo.com', 'y.z.foo.com').should be_true
    end
    it "should not match superdomains, or illegal domains" do
      domains_match('x.y.z.foo.com', 'z.foo.com').should be_false
      domains_match('foo.com', 'com').should be_false
    end
    it "should not match domains with and without a dot suffix together" do
      domains_match('foo.com.', 'foo.com').should be_false
    end
  end
  describe '.compute_search_domains' do
    it "should handle subdomains" do
      compute_search_domains('http://www.auth.foo.com/').should ==
       ['www.auth.foo.com', '.www.auth.foo.com', '.auth.foo.com']
    end
    it "should handle root domains" do
      compute_search_domains('http://foo.com/').should ==
      ['foo.com', '.foo.com']
    end
    it "should handle IP addresses" do
      compute_search_domains('http://127.0.0.1/').should ==
      ['127.0.0.1']
    end
    it "should handle local addresses" do
      compute_search_domains('http://zero/').should == 
      ['zero.local', '.zero.local', '.local']
    end
  end
end
