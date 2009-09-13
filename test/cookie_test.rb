require 'cookiejar'
require 'rubygems'

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
    it "should accept secure cookies" do
      cookie = Cookie.from_set_cookie 'https://www.google.com/a/blah', 'GALX=RgmSftjnbPM;Path=/a/;Secure'
      cookie.name.should == 'GALX'
      cookie.secure.should be_true
    end
  end
  begin
    require 'json'
    describe ".to_json" do
      it "should serialize a cookie to JSON" do
        c = Cookie.from_set_cookie 'https://localhost/', 'foo=bar;secure;expires=Fri, September 11 2009 18:10:00 -0700'
        json = c.to_json
        json.should be_a String
      end
    end
    describe ".json_create" do
      it "should deserialize JSON to a cookie" do
        json = "{\"name\":\"foo\",\"value\":\"bar\",\"domain\":\"localhost.local\",\"path\":\"\\/\",\"created_at\":\"2009-09-11 12:51:03 -0600\",\"expiry\":\"2009-09-11 19:10:00 -0600\",\"secure\":true}" 
        hash = JSON.parse json
        c = Cookie.json_create hash
        CookieValidation.validate_cookie 'https://localhost/', c
      end
      it "should automatically deserialize to a cookie" do
        json = "{\"json_class\":\"CookieJar::Cookie\",\"name\":\"foo\",\"value\":\"bar\",\"domain\":\"localhost.local\",\"path\":\"\\/\",\"created_at\":\"2009-09-11 12:51:03 -0600\",\"expiry\":\"2009-09-11 19:10:00 -0600\",\"secure\":true}" 
        c = JSON.parse json
        c.should be_a Cookie
        CookieValidation.validate_cookie 'https://localhost/', c
      end
    end
  rescue LoadError
    it "does not appear the JSON library is installed" do
      raise "please install the JSON library"
    end
  end
end
