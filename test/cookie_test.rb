require 'cookiejar'

include CookieJar

FOO_URL = 'http://localhost/foo'
AMMO_URL = 'http://localhost/ammo'
NETSCAPE_SPEC_SET_COOKIE_HEADERS =
[['CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT',
    FOO_URL],
  ['PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
    FOO_URL],
  ['SHIPPING=FEDEX; path=/foo',
    FOO_URL],
  ['PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
    FOO_URL],
  ['PART_NUMBER=RIDING_ROCKET_0023; path=/ammo',
    AMMO_URL]]
 
describe Cookie do
  describe "#from_set_cookie" do
    it "should handle cookies from the netscape spec" do
      NETSCAPE_SPEC_SET_COOKIE_HEADERS.each do |value|
        header, url = *value
        cookie = Cookie.from_set_cookie url, header
      end
    end
    it "should give back the input names and values" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'foo=bar'
      cookie.name.should == 'foo'
      cookie.value.should == 'bar'
    end
    it "should normalize domain names" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'foo=Bar;domain=LoCaLHoSt.local'
      cookie.domain.should == '.localhost.local'
    end
    it "should accept non-normalized .local" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'foo=bar;domain=.local'
      cookie.domain.should == '.local'
    end
  end
  describe '.validate_cookie' do
    localaddr = 'http://localhost/foo/bar/'
    it "should fail if version unset" do
      lambda do
        unversioned = Cookie.from_set_cookie localaddr, 'foo=bar'
        unversioned.instance_variable_set :@version, nil
        Cookie.validate_cookie localaddr, unversioned
      end.should raise_error InvalidCookieError
    end
    it "should fail if the path is more specific" do
      lambda do
        subdirred = Cookie.from_set_cookie localaddr, 'foo=bar;path=/foo/bar/baz'
        # validate_cookie localaddr, subdirred
      end.should raise_error InvalidCookieError
    end
    it "should fail if the path is different than the request" do
      lambda do
        difdirred = Cookie.from_set_cookie localaddr, 'foo=bar;path=/baz/'
        # validate_cookie localaddr, difdirred
      end.should raise_error InvalidCookieError
    end
    it "should fail if the domain has no dots" do
      lambda do
        nodot = Cookie.from_set_cookie 'http://zero/', 'foo=bar;domain=zero'
        # validate_cookie 'http://zero/', nodot
      end.should raise_error InvalidCookieError
    end
    it "should fail for explicit localhost" do
      lambda do
        localhost = Cookie.from_set_cookie localaddr, 'foo=bar;domain=localhost'
        # validate_cookie localaddr, localhost
      end.should raise_error InvalidCookieError
    end
    it "should fail for mismatched domains" do
      lambda do
        foobar = Cookie.from_set_cookie 'http://www.foo.com/', 'foo=bar;domain=bar.com'
        # validate_cookie 'http://www.foo.com/', foobar
      end.should raise_error InvalidCookieError
    end
    it "should fail for domains more than one level up" do
      lambda do
        xyz = Cookie.from_set_cookie 'http://x.y.z.com/', 'foo=bar;domain=z.com'
        # validate_cookie 'http://x.y.z.com/', xyz
      end.should raise_error InvalidCookieError
    end
    it "should fail for setting subdomain cookies" do
      lambda do
        subdomain = Cookie.from_set_cookie 'http://foo.com/', 'foo=bar;domain=auth.foo.com'
        # validate_cookie 'http://foo.com/', subdomain
      end.should raise_error InvalidCookieError
    end
    it "should handle a normal implicit internet cookie" do
      normal = Cookie.from_set_cookie 'http://foo.com/', 'foo=bar'
      Cookie.validate_cookie('http://foo.com/', normal).should be_true
    end
    it "should handle a normal implicit localhost cookie" do
      localhost = Cookie.from_set_cookie 'http://localhost/', 'foo=bar'
      Cookie.validate_cookie('http://localhost/', localhost).should be_true
    end
    it "should handle an implicit IP address cookie" do
      ipaddr =  Cookie.from_set_cookie 'http://127.0.0.1/', 'foo=bar'
      Cookie.validate_cookie('http://127.0.0.1/', ipaddr).should be_true
    end
    it "should handle an explicit domain on an internet site" do
      explicit = Cookie.from_set_cookie 'http://foo.com/', 'foo=bar;domain=.foo.com'
      Cookie.validate_cookie('http://foo.com/', explicit).should be_true
    end
    it "should handle setting a cookie explicitly on a superdomain" do
      superdomain = Cookie.from_set_cookie 'http://auth.foo.com/', 'foo=bar;domain=.foo.com'
      Cookie.validate_cookie('http://foo.com/', superdomain).should be_true
    end
    it "should handle explicitly setting a cookie" do
      explicit = Cookie.from_set_cookie 'http://foo.com/bar/', 'foo=bar;path=/bar/'
      Cookie.validate_cookie('http://foo.com/bar/', explicit)
    end
    it "should handle setting a cookie on a higher path" do
      higher = Cookie.from_set_cookie 'http://foo.com/bar/baz/', 'foo=bar;path=/bar/'
      Cookie.validate_cookie('http://foo.com/bar/baz/', higher)
    end
  end
  describe '.cookie_base_path' do
    it "should leave '/' alone" do
      Cookie.cookie_base_path('/').should == '/'
    end
    it "should strip off everything after the last '/'" do
      Cookie.cookie_base_path('/foo/bar/baz').should == '/foo/bar/'
    end
    it "should handle query parameters and fragments with slashes" do
      Cookie.cookie_base_path('/foo/bar?query=a/b/c#fragment/b/c').should == '/foo/'
    end
    it "should handle URI objects" do
      Cookie.cookie_base_path(URI.parse('http://www.foo.com/bar/')).should == '/bar/'
    end
    it "should preserve case" do
      Cookie.cookie_base_path("/BaR/").should == '/BaR/'
    end
  end
  describe '.determine_cookie_path' do
    it "should use the requested path when none is specified for the cookie" do
      Cookie.determine_cookie_path('http://foo.com/', nil).should == '/'
      Cookie.determine_cookie_path('http://foo.com/bar/baz', '').should == '/bar/'
    end
    it "should handle URI objects" do
      Cookie.determine_cookie_path(URI.parse('http://foo.com/bar/'), '').should == '/bar/'
    end
    it "should handle Cookie objects" do
      cookie = Cookie.from_set_cookie('http://foo.com/', "name=value;path=/")
      Cookie.determine_cookie_path('http://foo.com/', cookie).should == '/'
    end
    it "should ignore the request when a path is specified" do
      Cookie.determine_cookie_path('http://foo.com/ignorable/path', '/path/').should == '/path/'
    end
  end
  describe '.compute_search_domains' do
    it "should handle subdomains" do
      Cookie.compute_search_domains('http://www.auth.foo.com/').should ==
       ['www.auth.foo.com', '.www.auth.foo.com', '.auth.foo.com']
    end
    it "should handle root domains" do
      Cookie.compute_search_domains('http://foo.com/').should ==
      ['foo.com', '.foo.com']
    end
    it "should handle IP addresses" do
      Cookie.compute_search_domains('http://127.0.0.1/').should ==
      ['127.0.0.1']
    end
    it "should handle local addresses" do
      Cookie.compute_search_domains('http://zero/').should == 
      ['zero.local', '.zero.local', '.local']
    end
  end
  describe '.determine_cookie_domain' do
    it "should add a dot to the front of domains" do
      Cookie.determine_cookie_domain('http://foo.com/', 'foo.com').should == '.foo.com'
    end
    it "should not add a second dot if one present" do
      Cookie.determine_cookie_domain('http://foo.com/', '.foo.com').should == '.foo.com'
    end
    it "should handle Cookie objects" do
      c = Cookie.from_set_cookie('http://foo.com/', "foo=bar;domain=foo.com")
      Cookie.determine_cookie_domain('http://foo.com/', c).should == '.foo.com'
    end
    it "should handle URI objects" do
      Cookie.determine_cookie_domain(URI.parse('http://foo.com/'), '.foo.com').should == '.foo.com'
    end
    it "should use an exact hostname when no domain specified" do
      Cookie.determine_cookie_domain('http://foo.com/', '').should == 'foo.com'
    end
    it "should leave IPv4 addresses alone" do
      Cookie.determine_cookie_domain('http://127.0.0.1/', '127.0.0.1').should == '127.0.0.1'
    end
    it "should leave IPv6 addresses alone" do
      ['2001:db8:85a3::8a2e:370:7334', '::ffff:192.0.2.128'].each do |value|
        Cookie.determine_cookie_domain("http://[#{value}]/", value).should == value
      end
    end
  end
  describe ".effective_host" do
    it "should leave proper domains the same" do
      ['google.com', 'www.google.com', 'google.com.'].each do |value|
        Cookie.effective_host(value).should == value
      end
    end
    it "should handle a URI object" do
      Cookie.effective_host(URI.parse('http://example.com/')).should == 'example.com'
    end	
    it "should add a local suffix on unqualified hosts" do
      Cookie.effective_host('localhost').should == 'localhost.local'
    end
    it "should leave IPv4 addresses alone" do
      Cookie.effective_host('127.0.0.1').should == '127.0.0.1'
    end
    it "should leave IPv6 addresses alone" do
      ['2001:db8:85a3::8a2e:370:7334', ':ffff:192.0.2.128'].each do |value|
        Cookie.effective_host(value).should == value
      end
    end
    it "should lowercase addresses" do
      Cookie.effective_host('FOO.COM').should == 'foo.com'
    end
  end
  describe '.domains_match' do
    it "should handle exact matches" do
      Cookie.domains_match('foo', 'foo').should be_true
      Cookie.domains_match('foo.com', 'foo.com').should be_true
      Cookie.domains_match('127.0.0.1', '127.0.0.1').should be_true
      Cookie.domains_match('::ffff:192.0.2.128', '::ffff:192.0.2.128').should be_true
    end
    it "should handle matching a superdomain" do
      Cookie.domains_match('auth.foo.com', 'foo.com').should be_true
      Cookie.domains_match('x.y.z.foo.com', 'y.z.foo.com').should be_true
    end
    it "should not match superdomains, or illegal domains" do
      Cookie.domains_match('x.y.z.foo.com', 'z.foo.com').should be_false
      Cookie.domains_match('foo.com', 'com').should be_false
    end
    it "should not match domains with and without a dot suffix together" do
      Cookie.domains_match('foo.com.', 'foo.com').should be_false
    end
  end
  describe '.hostname_reach' do
    it "should find the next highest subdomain" do
      {'www.google.com' => 'google.com', 'auth.corp.companyx.com' => 'corp.companyx.com'}.each do |entry|
        Cookie.hostname_reach(entry[0]).should == entry[1]
      end
    end
    it "should handle domains with suffixed dots" do
      Cookie.hostname_reach('www.google.com.').should == 'google.com.'
    end
    it "should return nil for a root domain" do
      Cookie.hostname_reach('github.com').should be_nil
    end
    it "should return 'local' for a local domain" do
      ['foo.local', 'foo.local.'].each do |hostname|
        Cookie.hostname_reach(hostname).should == 'local'
      end
    end
    it "should handle mixed-case '.local'" do
      Cookie.hostname_reach('foo.LOCAL').should == 'local'
    end
    it "should return nil for an IPv4 address" do
      Cookie.hostname_reach('127.0.0.1').should be_nil
    end
    it "should return nil for IPv6 addresses" do
      ['2001:db8:85a3::8a2e:370:7334', '::ffff:192.0.2.128'].each do |value|
        Cookie.hostname_reach(value).should be_nil
      end
    end
  end
end