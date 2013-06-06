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
  describe "#from_set_cookie2" do
    it "should give back the input names and values" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'foo=bar;Version=1'
      cookie.name.should == 'foo'
      cookie.value.should == 'bar'
    end
    it "should normalize domain names" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'foo=Bar;domain=LoCaLHoSt.local;Version=1'
      cookie.domain.should == '.localhost.local'
    end
    it "should accept non-normalized .local" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'foo=bar;domain=.local;Version=1'
      cookie.domain.should == '.local'
    end
    it "should accept secure cookies" do
      cookie = Cookie.from_set_cookie2 'https://www.google.com/a/blah', 'GALX=RgmSftjnbPM;Path="/a/";Secure;Version=1'
      cookie.name.should == 'GALX'
      cookie.path.should == '/a/'
      cookie.secure.should be_true
    end
    it "should fail on unquoted paths" do
      lambda do 
        Cookie.from_set_cookie2 'https://www.google.com/a/blah', 
          'GALX=RgmSftjnbPM;Path=/a/;Secure;Version=1'
      end.should raise_error InvalidCookieError
    end
    it "should accept quoted values" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'foo="bar";Version=1'
      cookie.name.should == 'foo'
      cookie.value.should == '"bar"'
    end
    it "should accept poorly chosen names" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'Version=mine;Version=1'
      cookie.name.should == 'Version'
      cookie.value.should == 'mine'
    end
    it "should accept quoted parameter values" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'foo=bar;Version="1"'
    end
    it "should honor the discard and max-age parameters" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;max-age=100;discard;Version=1'
      cookie.should be_session
      cookie.should_not be_expired
      
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;max-age=100;Version=1'
      cookie.should_not be_session

      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;Version=1'
      cookie.should be_session
    end
    it "should handle quotable quotes" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f="\"";Version=1'
      cookie.value.should eql '"\""'
    end
    it "should handle quotable apostrophes" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f="\;";Version=1'
      cookie.value.should eql '"\;"'
    end
  end
  describe '#decoded_value' do
    it "should leave normal values alone" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;Version=1'
      cookie.decoded_value.should eql 'b'
    end
    it "should attempt to unencode quoted values" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f="\"b";Version=1'
      cookie.value.should eql '"\"b"'
      cookie.decoded_value.should eql '"b'
    end
  end
  describe '#to_s' do
    it "should handle a simple cookie" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'f=b'
      cookie.to_s.should == 'f=b'
      cookie.to_s(1).should == '$Version=0;f=b;$Path="/"'
    end
    it "should report an explicit domain" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;Version=1;Domain=.local'
      cookie.to_s(1).should == '$Version=1;f=b;$Path="/";$Domain=.local'
    end
    it "should return specified ports" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;Version=1;Port="80,443"'
      cookie.to_s(1).should == '$Version=1;f=b;$Path="/";$Port="80,443"'
    end
    it "should handle specified paths" do
      cookie = Cookie.from_set_cookie 'http://localhost/bar/', 'f=b;path=/bar/'
      cookie.to_s.should == 'f=b'
      cookie.to_s(1).should == '$Version=0;f=b;$Path="/bar/"'
    end
    it "should omit $Version header when asked" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'f=b'
      cookie.to_s(1,false).should == 'f=b;$Path="/"'
    end
  end
  describe '#should_send?' do
    it "should not send if ports do not match" do
      cookie = Cookie.from_set_cookie2 'http://localhost/', 'f=b;Version=1;Port="80"'
      cookie.should_send?("http://localhost/", false).should be_true
      cookie.should_send?("https://localhost/", false).should be_false
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
        c = JSON.parse json, :create_additions => true
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
