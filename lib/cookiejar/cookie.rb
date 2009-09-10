require 'time'
require 'cookiejar/cookie_logic'

module CookieJar
  
  # Defines the parsing logic and data model of a HTTP Cookie.
  # Note that the data values within the cookie may be different from the
  # values described in the literal cookie declaration.
  # Specifically, the 'domain' and 'path' values may be set to defaults 
  # based on the requested resource that resulted in the cookie being set.
  class Cookie
    include CookieLogic
    extend CookieLogic
    
    # The name and value of the cookie. These values are mandatory for all
    # cookies
    attr_reader :name, :value
    # The domain and path of the cookie. These values will be set on all
    # legal cookie objects, based on the requested URI if not set literally
    attr_reader :domain, :path
    # The secure flag is set to indicate that the cookie should only be
    # sent securely. Nearly all implementations assume this to mean over
    # SSL/TLS
    attr_reader :secure
    # Popular browser extension to mark a cookie as invisible to code running
    # within the browser, such as JavaScript
    attr_reader :http_only
    
    #-- Attributes for RFC 2965 cookies
    
    # Version indicator - version is 0 for netscape cookies, 
    # and 1 for RFC 2965 cookies
    attr_reader :version
    # Comment (or location) describing cookie.
    attr_reader :comment, :comment_url
    # Discard
    attr_reader :discard
    attr_reader :ports
    attr_reader :created_at

    def expires_at
      if @expiry.nil? || @expiry.is_a?(Time)
        @expiry
      else
        @created_at + @expiry
      end
    end
    
    def max_age
      if @expiry.is_a? Time
        @expiry - @created_at
      else
        @expiry
      end
    end
    
    def expired?
      expires_at != nil && (Time.now > expires_at)
    end

    # Create a cookie based on an absolute URI and the string value of a
    # 'Set-Cookie' header.
    def self.from_set_cookie(request_uri, set_cookie_value)
      include CookieLogic
      args = {}
      params=set_cookie_value.split(/;\s*/)
      params.each do |param|
        result = PARAM1.match param
        if (!result) 
          raise InvalidCookieError.new("Invalid cookie parameter in cookie '#{set_cookie_value}'")
        end
        key = result[1].downcase.to_sym
        keyvalue = result[2]
        case key
        when :expires
          args[:expires_at] = Time.parse(keyvalue)
        when :domain
          args[:domain] = keyvalue
        when :path
          args[:path] = keyvalue
        when 'SECURE'
          args[:secure] = true
        when 'HTTPONLY'
          args[:http_only] = true
        else
          args[:name] = result[1]
          args[:value] = keyvalue
        end
      end
      args[:domain] = determine_cookie_domain request_uri, args[:domain]
      args[:path] = determine_cookie_path request_uri, args[:path]
      args[:version] = 0
      cookie = Cookie.new args
      validate_cookie request_uri, cookie
      cookie
    end

    def to_s
      %^"#{name}=#{value}#{if(domain) then "; domain=#{domain}" end}#{if (expiry) then "; expiry=#{expiry}" end}#{if (path) then "; path=#{path}" end}#{if (secure) then "; secure" end }#{if (http_only) then "; HTTPOnly" end}^
    end

    # Check whether a cookie meets all of the rules to be created, based on 
    # its internal settings and the URI it came from.
    #
    # returns true on success, but will raise an InvalidCookieError on failure
    # with an appropriate error message
    def self.validate_cookie request_uri, cookie
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
    
      request_host = effective_host uri.host
      request_path = uri.path
      request_secure = (uri.scheme == 'https')
      cookie_host = cookie.domain
      cookie_path = cookie.path
    
      # From RFC 2965, Section 3.3.2 Rejecting Cookies
    
      # A user agent rejects (SHALL NOT store its information) if the 
      # Version attribute is missing. Note that the legacy Set-Cookie
      # directive will result in an implicit version 0.
      unless cookie.version
        raise InvalidCookieError, "Cookie version not supplied (or implicit with Set-Cookie)"
      end

      # The value for the Path attribute is not a prefix of the request-URI
      unless request_path.start_with? cookie_path 
        raise InvalidCookieError, "Cookie path should match or be a subset of the request path"
      end

      # The value for the Domain attribute contains no embedded dots, and the value is not .local
      # Note: we also allow IPv4 and IPv6 addresses
      unless cookie_host =~ IPADDR || cookie_host =~ /.\../ || cookie_host == '.local'
        raise InvalidCookieError, "Cookie domain format is not legal"
      end
    
      # The effective host name that derives from the request-host does
      # not domain-match the Domain attribute.
      #
      # The request-host is a HDN (not IP address) and has the form HD,
      # where D is the value of the Domain attribute, and H is a string
      # that contains one or more dots.
      effective_host = effective_host uri
      unless domains_match effective_host, cookie_host
        raise InvalidCookieError, "Cookie domain is inappropriate based on request hostname"
      end
    
      # The Port attribute has a "port-list", and the request-port was
      # not in the list.
      unless cookie.ports.nil? || cookie.ports.length != 0
        unless cookie.ports.find_index uri.port
          raise InvalidCookieError, "incoming request port does not match cookie port(s)"
        end
      end
    
      # Note: 'secure' is not explicitly defined as an SSL channel, and no
      # test is defined around validity and the 'secure' attribute
      true
    end
    # Return true if (given a URI, a cookie object and other options) a cookie
    # should be sent to a host. Note that this currently ignores domain.
    #
    # The third option, 'script', indicates that cookies with the 'http only'
    # extension should be ignored
    def should_send? uri, script
      # cookie path must start with the uri, it must not be a secure cookie being sent over http,
      # and it must not be a http_only cookie sent to a script
      path_match   = uri.path.start_with? @path
      secure_match = !(@secure && uri.scheme == 'http') 
      script_match = !(script && @http_only)
      expiry_match = !expired?
      path_match && secure_match && script_match && expiry_match
    end
  protected
    PARAM1 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE1})?\Z/
    # PARAM2 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE2})?\Z/

    def initialize(*params)
      case params.length
      when 1
        args = params[0]
      when 2
        args = {:name => params[0], :value => params[1], :version => 0}
      else
        raise ArgumentError.new "wrong number of arguments (expected 1 or 2)"
      end

      @created_at = Time.now    
      @domain       = args[:domain]
      @expiry       = args[:max_age]   || args[:expires_at] || nil
      @path         = args[:path]
      @secure       = args[:secure]    || false
      @http_only    = args[:http_only] || false
      @name         = args[:name]
      @value        = args[:value]
      @version      = args[:version]
      @comment      = args[:comment]
      @comment_url  = args[:comment_url]
      @discard      = args[:discard]
      @ports        = args[:ports]
      
      if @ports.is_a? Integer
        @ports = [@ports]
      end      
    end
  end
end
