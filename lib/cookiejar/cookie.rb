require 'time'
require 'uri'
require 'cookiejar/cookie_validation'

module CookieJar
  
  # Defines the parsing logic and data model of a HTTP Cookie.
  # Note that the data values within the cookie may be different from the
  # values described in the literal cookie declaration.
  # Specifically, the 'domain' and 'path' values may be set to defaults 
  # based on the requested resource that resulted in the cookie being set.
  class Cookie
  
    # The mandatory name and value of the cookie
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
    
    def is_expired?
      expires_at != nil && Time.now > expires_at
    end
    
    def is_session?
      @expiry == nil
    end
    
    # Create a cookie based on an absolute URI and the string value of a
    # 'Set-Cookie' header.
    def self.from_set_cookie request_uri, set_cookie_value 
      args = CookieJar::CookieValidation.parse_set_cookie set_cookie_value
      args[:domain] = CookieJar::CookieValidation.determine_cookie_domain request_uri, args[:domain]
      args[:path] = CookieJar::CookieValidation.determine_cookie_path request_uri, args[:path]
      cookie = Cookie.new args
      CookieJar::CookieValidation.validate_cookie request_uri, cookie
      cookie
    end

    def to_s
      "#{name}=#{value}"
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
      expiry_match = !is_expired?
      path_match && secure_match && script_match && expiry_match
    end
    
    def to_json *a
      result = {
        :json_class => self.class.name,
        :name => @name,
        :value => @value,
        :domain => @domain,
        :path => @path,
        :created_at => @created_at
      }
      {
        :expiry => @expiry,
        :secure => (true if @secure),
        :http_only => (true if @http_only),
        :version => (@version if version != 0),
        :comment => @comment,
        :comment_url => @comment_url,
        :discard => (true if @discard),
        :ports => @ports
      }.each do |name, value|
        result[name] = value if value
      end
      result.to_json(*a)
    end
    def self.json_create o
      params = o.inject({}) do |hash, (key, value)|
        hash[key.to_sym] = value
        hash
      end
      params[:version] ||= 0
      params[:created_at] = Time.parse params[:created_at]
      if params[:expiry].is_a? String
        params[:expires_at] = Time.parse params[:expiry]
      else
        params[:max_age] = params[:expiry]
      end
      params.delete :expiry

      self.new params
    end
    def self.compute_search_domains request_uri
      CookieValidation.compute_search_domains request_uri
    end
  protected
    def initialize args

      @created_at   = args[:created_at] || Time.now    
      @domain       = args[:domain]
      @expiry       = args[:max_age]   || args[:expires_at]
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