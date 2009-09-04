require 'cookiejar'

NETSCAPE_SPEC_SET_COOKIE_HEADERS =
['CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT',
 'PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
 'SHIPPING=FEDEX; path=/foo',
 'PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
 'PART_NUMBER=RIDING_ROCKET_0023; path=/ammo']
 
describe Cookie do
  describe "#from_set_cookie" do
    it "should handle cookies from the netscape spec" do
      NETSCAPE_SPEC_SET_COOKIE_HEADERS.each do |header|
        cookie = Cookie.from_set_cookie 'http://localhost', header
      end
    end
    it "should give back the input names and values" do
      cookie = Cookie.from_set_cookie 'http://localhost/', 'foo=bar'
      cookie.name.should == 'foo'
      cookie.value.should == 'bar'
    end
  end
end