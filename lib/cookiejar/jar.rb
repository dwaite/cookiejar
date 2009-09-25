require 'cookiejar/cookie'
 
module CookieJar
  # A cookie store for client side usage. 
  # - Enforces cookie validity rules
  # - Returns just the cookies valid for a given URI
  # - Handles expiration of cookies
  # - Allows for persistence of cookie data (with or without session) 
  #
  #--
  #
  # Internal format:
  # 
  # Internally, the data structure is a set of nested hashes.
  # Domain Level:
  # At the domain level, the hashes are of individual domains,
  # down-cased and without any leading period. For instance, imagine cookies
  # for .foo.com, .bar.com, and .auth.bar.com:
  #
  #   { 
  #     "foo.com"      : (host data),
  #     "bar.com"      : (host data),
  #     "auth.bar.com" : (host data)
  #   }
  #
  # Lookups are done both for the matching entry, and for an entry without
  # the first segment up to the dot, ie. for /^\.?[^\.]+\.(.*)$/.
  # A lookup of auth.bar.com would match both bar.com and 
  # auth.bar.com, but not entries for com or www.auth.bar.com.
  #
  # Host Level:
  # Entries are in an hash, with keys of the path and values of a hash of
  # cookie names to cookie object
  #
  #   {
  #     "/" : {"session" : (Cookie object), "cart_id" : (Cookie object)}
  #     "/protected" : {"authentication" : (Cookie Object)}
  #   }
  #
  # Paths are given a straight prefix string comparison to match.
  # Further filters <secure, http only, ports> are not represented in this
  # heirarchy. 
  #
  # Cookies returned are ordered solely by specificity (length) of the
  # path.
  class Jar
    # Create a new empty Jar
    def initialize
  	  @domains = {}
    end
    
    # Given a request URI and a literal Set-Cookie header value, attempt to
    # add the cookie to the cookie store.
    # 
    # @param [String, URI] request_uri the resource returning the header
    # @param [String] cookie_header_value the contents of the Set-Cookie
    # @return [Cookie] which was created and stored
    # @raise [InvalidCookieError] if the cookie header did not validate
    def set_cookie request_uri, cookie_header_value
    	cookie = Cookie.from_set_cookie request_uri, cookie_header_value
    	add_cookie cookie
    end
    
    # Add a pre-existing cookie object to the jar.
    #
    # @param [Cookie] cookie a pre-existing cookie object
    # @return [Cookie] the cookie added to the store
    def add_cookie cookie
      domain_paths = find_or_add_domain_for_cookie cookie
  	  add_cookie_to_path domain_paths, cookie
  	  cookie
  	end
  	
  	# Return an array of all cookie objects in the jar
  	#
  	# @return [Array<Cookie>] all cookies. Includes any expired cookies
  	# which have not yet been removed with expire_cookies
  	def to_a
  	  result = []
  	  @domains.values.each do |paths|
  	    paths.values.each do |cookies|
  	      cookies.values.inject result, :<<
	      end
      end
      result
	  end
	  
	  # Return a JSON 'object' for the various data values. Allows for
    # persistence of the cookie information
    #
    # @param [Array] a options controlling output JSON text 
    #   (usually a State and a depth)
    # @return [String] JSON representation of object data 
	  def to_json *a
	    {
	      'json_class' => self.class.name,
	      'cookies' => (to_a.to_json *a)
      }.to_json *a
    end
    
    # Create a new Jar from a JSON-backed hash
    #
    # @param o [Hash] the expanded JSON object
    # @return [CookieJar] a new CookieJar instance
    def self.json_create o
      if o.is_a? Hash
        o = o['cookies']
      end
      cookies = o.inject [] do |result, cookie_json|
        result << (Cookie.json_create cookie_json)
      end
      self.from_a cookies
    end
    
    # Create a new Jar from an array of Cookie objects. Expired cookies
    # will still be added to the archive, and conflicting cookies will
    # be overwritten by the last cookie in the array.
    #
    # @param [Array<Cookie>] cookies array of cookie objects
    # @return [CookieJar] a new CookieJar instance
    def self.from_a cookies
      jar = new
      cookies.each do |cookie|
        jar.add_cookie cookie
      end
      jar
    end

    # Look through the jar for any cookies which have passed their expiration
    # date, or session cookies from a previous session
    #
    # @param session [Boolean] whether session cookies should be expired,
    #   or just cookies past their expiration date.
    def expire_cookies session = false
      @domains.delete_if do |domain, paths|
        paths.delete_if do |path, cookies|
          cookies.delete_if do |cookie_name, cookie|
            cookie.is_expired? || (session && cookie.is_session?)
          end
          cookies.empty?
        end
        paths.empty?
      end
    end
    
    # Given a request URI, return a sorted list of Cookie objects. Cookies
    # will be in order per RFC 2965 - sorted by longest path length, but
    # otherwise unordered.
    #
    # @param [String, URI] request_uri the address the HTTP request will be
    #   sent to
    # @param [Hash] opts options controlling returned cookies
    # @option opts [Boolean] :script (false) Cookies marked HTTP-only will be ignored
    #   if true
    # @return [Array<Cookie>] cookies which should be sent in the HTTP request
    def get_cookies request_uri, opts = { }
  	  uri = to_uri request_uri
    	hosts = Cookie.compute_search_domains uri
	
    	results = []
    	hosts.each do |host|
    	  domain = find_domain host
    	  domain.each do |path, cookies|
    		  if uri.path.start_with? path
      		  results += cookies.values.select do |cookie|
        			cookie.should_send? uri, opts[:script]
        		end
        	end
      	end
      end
    	#Sort by path length, longest first
    	results.sort do |lhs, rhs|
    	  rhs.path.length <=> lhs.path.length
    	end
    end
    
    # Given a request URI, return a string Cookie header.Cookies will be in
    # order per RFC 2965 - sorted by longest path length, but otherwise
    # unordered.
    #
    # @param [String, URI] request_uri the address the HTTP request will be
    #   sent to
    # @param [Hash] opts options controlling returned cookies
    # @option opts [Boolean] :script (false) Cookies marked HTTP-only will be ignored
    #   if true
    # @return String value of the Cookie header which should be sent on the
    #   HTTP request
    def get_cookie_header request_uri, opts = { }
    	cookies = get_cookies request_uri, opts
    	cookies.map do |cookie|
    	  cookie.to_s
  	  end.join ";"
    end

  protected  

    def to_uri request_uri
      (request_uri.is_a? URI)? request_uri : (URI.parse request_uri)
    end
    
    def find_domain host
    	@domains[host] || {}
    end

    def find_or_add_domain_for_cookie cookie
    	@domains[cookie.domain] ||= {}
    end
	
    def add_cookie_to_path paths, cookie
    	path_entry = (paths[cookie.path] ||= {})
    	path_entry[cookie.name] = cookie
    end
  end
end