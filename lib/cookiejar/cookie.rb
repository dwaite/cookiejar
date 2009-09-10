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
    # 1 for RFC 2965 cookies
    attr_reader :version
    attr_reader :comment, :comment_url
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
      expires_at  != nil && Time.now > expires_at
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
      Cookie.new(args)
    end

    def to_s
      %^"#{name}=#{value}#{if(domain) then "; domain=#{domain}" end}#{if (expiry) then "; expiry=#{expiry}" end}#{if (path) then "; path=#{path}" end}#{if (secure) then "; secure" end }#{if (http_only) then "; HTTPOnly" end}^
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
