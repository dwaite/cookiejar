require 'uri'
require 'cookiejar/cookie_common'

module CookieJar
  module CookieLogic
    module PATTERN
      include URI::REGEXP::PATTERN

      TOKEN = '[^(),\/<>@;:\\\"\[\]?={}\s]*'
      VALUE1 = "([^;]*)"
      IPADDR = "#{IPV4ADDR}|#{IPV6ADDR}"
      BASE_HOSTNAME = "(?:#{DOMLABEL}\\.)((?:(?:#{DOMLABEL}\\.)+(?:#{TOPLABEL}\\.?)|local))"

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
  
    # Compute the effective host (RFC 2965, section 1)
    # [host] a string or URI.
    #
    # Has the added additional logic of searching for interior dots specifically, and
    # matches colons to prevent .local being suffixed on IPv6 addresses
    def effective_host(host)
      hostname = host.is_a?(URI) ? host.host : host
      hostname = hostname.downcase
    
      if /.(?:[\.:])./.match(hostname)
        hostname
      else
        hostname + '.local'
      end
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
    def determine_cookie_domain (request_uri, cookie_domain)
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      domain = cookie_domain.is_a?(Cookie) ? cookie_domain.domain : cookie_domain
    
      if domain == nil || domain.empty?
        domain = effective_host(uri.host)
      else
        domain = domain.downcase
        if (domain =~ IPADDR || domain.start_with?('.'))
          domain
        else
          ".#{domain}" 
        end
      end
    end

    # Processes cookie path data using the following rules:
    # Paths are separated by '/' characters, and accepted values are truncated
    # to the last '/' character. If no path is specified in the cookie, a path
    # value will be taken from the request URI which was used for the site.
    #
    # Note that this will not attempt to detect a mismatch of the request uri domain
    # and explicitly specified cookie path
    def determine_cookie_path(request_uri, cookie_path)
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      cookie_path = cookie_path.is_a?(Cookie) ? cookie_path.path : cookie_path
    
      if (cookie_path == nil || cookie_path.empty?)
        cookie_path = cookie_base_path uri.path
      end
      cookie_path
    end

    # Compute the reach of a hostname (RFC 2965, section 1)
    # Determines the next highest superdomain, or nil if none valid
    def hostname_reach hostname
      host = hostname.is_a?(URI) ? hostname.host : hostname
      BASE_HOSTNAME.match(host) && $~[1] || nil
    end

    # Compute the base of a path.   
    def cookie_base_path(path)
      path = path.is_a?(URI) ? path.path : path
      BASE_PATH.match(path)[1]
    end
  
    # Compare a base domain against the base domain to see if they match, or
    # if the base domain is reachable
    def domains_match tested_domain,base_domain
      return true if (tested_domain == base_domain || ".#{tested_domain}" == base_domain)
      lhs = effective_host tested_domain
      rhs = effective_host base_domain
      lhs == rhs || ".#{lhs}" == rhs || hostname_reach(lhs) == rhs || ".#{hostname_reach lhs}" == rhs
    end
  
    # Given a URI, compute the relevant search domains for pre-existing
    # cookies. This includes all the valid dotted forms for a named or IP
    # domains.
    def compute_search_domains request_uri
      uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
      host = effective_host uri
      result = [host]
      if (host !~ IPADDR)
        result << ".#{host}"
      end
      base = hostname_reach host
      if (base)
        result << ".#{base}"
      end
      result
    end
  end
end