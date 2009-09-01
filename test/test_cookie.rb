require 'lib/cookiejar'

NETSCAPE_SPEC_SET_COOKIE_HEADERS =
['CUSTOMER=WILE_E_COYOTE; path=/; expires=Wednesday, 09-Nov-99 23:12:40 GMT',
 'PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
 'SHIPPING=FEDEX; path=/foo',
 'PART_NUMBER=ROCKET_LAUNCHER_0001; path=/',
 'PART_NUMBER=RIDING_ROCKET_0023; path=/ammo']
describe Cookie do
  describe ".parse" do
    it "should handle cookies from the netscape spec" do
      NETSCAPE_SPEC_SET_COOKIE_HEADERS.each do |header|
        cookie = Cookie.parse 'http://localhost', header
        puts cookie.to_s
      end
    end
  end
end