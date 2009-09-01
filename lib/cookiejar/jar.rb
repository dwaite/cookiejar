# A cookie store for client side usage. 
# - Enforces cookie validity rules
# - Returns just the cookies valid for a given URI
# - Handles expiration of cookies
# - Allows for persistence of cookie data (with or without sessoin) 
#
#--
# Internal format:
# 
# Internally, the data structure is a set of nested hashes.
# Domain Level:
# At the domain level, the hashes are of individual domains,
# down-cased and without any leading period. For instance, imagine cookies
# for .foo.com, .bar.com, and .auth.bar.com:
#
# { 
#   "foo.com"      : <host data>,
#   "bar.com"      : <host data>,
#   "auth.bar.com" : <host data>
# }
# Lookups are done both for the matching entry, and for an entry without
# the first segment up to the dot, ie. for /^\.?[^\.]+\.(.*)$/.
# A lookup of auth.bar.com would match both bar.com and 
# auth.bar.com, but not entries for com or www.auth.bar.com.
#
# Host Level:
# Entries are in an hash, with keys of the path and values of either a single
# or array of cookies.
#
# {
#   "/" : [<Cookie>, <Cookie>],
#   "/protected" : <Cookie>
# }
#
# Paths are given a straight prefix string comparison to match.
# Further filters <secure, http only, ports> are not represented in this
# heirarchy. 
#
# Cookies returned are ordered solely by specificity (length) of the
# path. 
class Jar
  def set_cookie request_uri, cookie_header_value
    uri = request_uri.is_a?(URI) ? request_uri : URI.parse(request_uri)
    host = effective_host uri
    cookie = Cookie.parse(cookie_header_value)
    if (cookie_valid? uri, cookie)
      domain_paths = find_domain_for_cookie(cookie)
      add_cookie_to_path(domain_paths,cookie)
      cookie
    else
      nil
    end
  end
  
  # Compute the effective host (RFC 2965, section 1)
  # [host] a string or URI
  def self.effective_host(host)
    hostname = host.is_a?(URI) ? host.hostname : host
    if hostname.include? '.'
      hostname
    else
      hostname + '.local'
    end
  end
  
  # process cookie data for a domain. lowercase the text and strip off
  # any leading period
  def self.cookie_domain (cookie)
    domain = cookie.is_a? Cookie ? cookie.domain : cookie
    domain = domain.downcase
    
    if (cookie_domain_name[0] == '.')
      domain.slice(1,domain.length)
    else
      domain
    end
  end
    
  def find_domain_for_cookie(cookie)
    domain = cookie_domain(cookie)
    @domains[domain] ||= {}
  end
  
  def add_cookie_to_path (paths, cookie)
    path_entry = paths[cookie.path]
    if (!path_entry)
      paths[cookie.path] = cookie
    elsif (path_entry.is_a? Cookie)
      if path_entry.name = cookie.name
        paths[cookie.path] = cookie
      else
        paths[cookie.path] = [path_entry, cookie]
      end
    else
      found = false
      paths_entry.each do |original_cookie|
        if cookie.name == original_cookie.name
          found = true
          cookie
        else
          original_cookie
        end
      end
      if !found
        paths_entry << cookie
      end
    end
  end
  
  def self.check_cookie request_uri, cookie
    request_host = uri.hostname
    request_path = uri.path
    request_secure = uri.scheme == 'https'
    
    if !valid_cookie_domain_settings(cookie.domain) ||
       (!cookie.secure && request_secure) ||
        
      return nill
  end
  
  def self.valid_cookie_domain? domain
    # very quick check, not univerally valid
    domain =~ /^\.?([^\.]+\.)+[^\.]+$/
  end
end