require 'time'
require 'uri'
require 'cookiejar/cookie_common'

module CookieJar
  
  # Defines the parsing logic and data model of a HTTP Cookie.
  # Note that the data values within the cookie may be different from the
  # values described in the literal cookie declaration.
  # Specifically, the 'domain' and 'path' values may be set to defaults 
  # based on the requested resource that resulted in the cookie being set.
  class Cookie
    module PATTERN
      include URI::REGEXP::PATTERN

      TOKEN = '[^(),\/<>@;:\\\"\[\]?={}\s]*'
      VALUE1 = "([^;]*)"
      IPADDR = "#{IPV4ADDR}|#{IPV6ADDR}"
      BASE_HOSTNAME = "(?:#{DOMLABEL}\\.)(?:((?:(?:#{DOMLABEL}\\.)+(?:#{TOPLABEL}\\.?))|local))"

      # QUOTED_PAIR = "\\\\[\\x00-\\x7F]"
      # LWS = "\\r\\n(?:[ \\t]+)"
      # TEXT="[\\t\\x20-\\x7E\\x80-\\xFF]|(?:#{LWS})"
      # QDTEXT="[\\t\\x20-\\x21\\x23-\\x7E\\x80-\\xFF]|(?:#{LWS})"
      # QUOTED_TEXT = "\\\"((?:#{QDTEXT}|#{QUOTED_PAIR})*)\\\""
      # VALUE2 = "(#{TOKEN})|#{QUOTED_TEXT}"

    end
    BASE_HOSTNAME = /#{PATTERN::BASE_HOSTNAME}/
    BASE_PATH = /\A((?:[^\/?#]*\/)*)/
    IPADDR = /\A#{PATTERN::IPADDR}\Z/
    # HDN = /\A#{PATTERN::HOSTNAME}\Z/
    # TOKEN = /\A#{PATTERN::TOKEN}\Z/
    # TWO_DOT_DOMAINS = /\A\.(com|edu|net|mil|gov|int|org)\Z/
  
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
    
    def expired?
      expires_at != nil && Time.now > expires_at
    end

    # Create a cookie based on an absolute URI and the string value of a
    # 'Set-Cookie' header.
    def self.from_set_cookie request_uri, set_cookie_value 
      args = { }
      params=set_cookie_value.split /;\s*/
      params.each do |param|
        result = PARAM1.match param
        if !result
          raise InvalidCookieError.new "Invalid cookie parameter in cookie '#{set_cookie_value}'"
        end
        key = result[1].downcase.to_sym
        keyvalue = result[2]
        case key
        when :expires
          args[:expires_at] = Time.parse keyvalue
        when :domain
          args[:domain] = keyvalue
        when :path
          args[:path] = keyvalue
        when :secure
          args[:secure] = true
        when :httponly
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
      %^"#{name}=#{value}#{if domain then "; domain=#{domain}" end}#{if expiry then "; expiry=#{expiry}" end}#{if path then "; path=#{path}" end}#{if secure then "; secure" end }#{if http_only then "; HTTPOnly" end}^
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
      
      errors = []
    
      # From RFC 2965, Section 3.3.2 Rejecting Cookies
    
      # A user agent rejects (SHALL NOT store its information) if the 
      # Version attribute is missing. Note that the legacy Set-Cookie
      # directive will result in an implicit version 0.
      unless cookie.version
        errors << "Version missing"
      end

      # The value for the Path attribute is not a prefix of the request-URI
      unless request_path.start_with? cookie_path 
        errors << "Path is not a prefix of the request uri path"
      end

      unless cookie_host =~ IPADDR || #is an IPv4 or IPv6 address
        cookie_host =~ /.\../ || #contains an embedded dot
        cookie_host == '.local' #is the domain cookie for local addresses
        errors << "Domain format is illegal"
      end
    
      # The effective host name that derives from the request-host does
      # not domain-match the Domain attribute.
      #
      # The request-host is a HDN (not IP address) and has the form HD,
      # where D is the value of the Domain attribute, and H is a string
      # that contains one or more dots.
      effective_host = effective_host uri
      unless domains_match effective_host, cookie_host
        errors << "Domain is inappropriate based on request URI hostname"
      end
    
      # The Port attribute has a "port-list", and the request-port was
      # not in the list.
      unless cookie.ports.nil? || cookie.ports.length != 0
        unless cookie.ports.find_index uri.port
          errors << "Ports list does not contain request URI port"
        end
      end

      raise InvalidCookieError.new errors unless errors.empty?

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
    
    # Compute the base of a path.   
    def self.cookie_base_path path
      path = path.is_a?(URI) ? path.path : path
      BASE_PATH.match(path)[1]
    end
    
    # Processes cookie path data using the following rules:
    # Paths are separated by '/' characters, and accepted values are truncated
    # to the last '/' character. If no path is specified in the cookie, a path
    # value will be taken from the request URI which was used for the site.
    #
    # Note that this will not attempt to detect a mismatch of the request uri domain
    # and explicitly specified cookie path
    def self.determine_cookie_path request_uri, cookie_path
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      cookie_path = cookie_path.is_a?(Cookie) ? cookie_path.path : cookie_path
    
      if cookie_path == nil || cookie_path.empty?
        cookie_path = cookie_base_path uri.path
      end
      cookie_path
    end
    
    # Given a URI, compute the relevant search domains for pre-existing
    # cookies. This includes all the valid dotted forms for a named or IP
    # domains.
    def self.compute_search_domains request_uri
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      host = effective_host uri
      result = [host]
      if host !~ IPADDR
        result << ".#{host}"
      end
      base = hostname_reach host
      if base
        result << ".#{base}"
      end
      result
    end
    
    # Processes cookie domain data using the following rules:
    # Domains strings of the form .foo.com match 'foo.com' and all immediate
    # subdomains of 'foo.com'. Domain strings specified of the form 'foo.com' are
    # modified to '.foo.com', and as such will still apply to subdomains.
    #
    # Cookies without an explicit domain will have their domain value taken directly
    # from the URL, and will _NOT_ have any leading dot applied. For example, a request
    # to http://foo.com/ will cause an entry for 'foo.com' to be created - which applies
    # to foo.com but no subdomain.
    #
    # Note that this will not attempt to detect a mismatch of the request uri domain
    # and explicitly specified cookie domain
    def self.determine_cookie_domain request_uri, cookie_domain
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      domain = cookie_domain.is_a?(Cookie) ? cookie_domain.domain : cookie_domain
    
      if domain == nil || domain.empty?
        domain = effective_host uri.host
      else
        domain = domain.downcase
        if domain =~ IPADDR || domain.start_with?('.')
          domain
        else
          ".#{domain}" 
        end
      end
    end
    # Compute the effective host (RFC 2965, section 1)
    # [host] a string or URI.
    #
    # Has the added additional logic of searching for interior dots specifically, and
    # matches colons to prevent .local being suffixed on IPv6 addresses
    def self.effective_host host
      hostname = host.is_a?(URI) ? host.host : host
      hostname = hostname.downcase
    
      if /.[\.:]./.match(hostname) || hostname == '.local'
        hostname
      else
        hostname + '.local'
      end
    end  
    # Compare a base domain against the base domain to see if they match, or
    # if the base domain is reachable
    def self.domains_match tested_domain,base_domain
      return true if (tested_domain == base_domain || ".#{tested_domain}" == base_domain)
      lhs = effective_host tested_domain
      rhs = effective_host base_domain
      lhs == rhs || ".#{lhs}" == rhs || hostname_reach(lhs) == rhs || ".#{hostname_reach lhs}" == rhs
    end
    # Compute the reach of a hostname (RFC 2965, section 1)
    # Determines the next highest superdomain, or nil if none valid
    def self.hostname_reach hostname
      host = hostname.is_a?(URI) ? hostname.host : hostname
      host = host.downcase
      match = BASE_HOSTNAME.match host
      if match
        match[1]
      end
    end
  protected
    PARAM1 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE1})?\Z/
    # PARAM2 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE2})?\Z/

    def initialize *params
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
