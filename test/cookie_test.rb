require 'cookiejar'
require 'cookiejar/cookie_logic'

include CookieJar
include CookieLogic

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
end