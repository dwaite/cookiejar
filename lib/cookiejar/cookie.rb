require 'date'
require 'cookiejar/cookie_logic'

class Cookie
  include CookieLogic
  
  attr_reader :name, :value
  attr_reader :created_at
  attr_reader :expiry
  attr_reader :domain, :path
  attr_reader :secure, :http_only
  attr_reader :version
#  attr_accessor :version
#  attr_accessor :comment, :comment_url
#  attr_accessor :discard
#  attr_accessor :ports

  def expires_at
    if expiry.is_a? DateTime
      expiry
    else
      Time.now + expiry
    end
  end
  def max_age
    if expiry.is_a? Integer
      expiry
    else
      expiry - Time.now
    end
  end 
  def port
    nil
  end   
  def initialize(uri, *params)

    case params.length
    when 1
      args = params[0]
    when 2
      args = {:name => args[0], :value => args[1]}
    else
      raise ArgumentError.new "wrong number of arguments (expected 1 or 2)"
    end
    
    @domain    = determine_cookie_domain(uri, args[:domain])
    @expiry    = args[:max_age]   || args[:expires_at] || nil
    @path      = determine_cookie_path(uri, args[:path])
    @secure    = args[:secure]    || false
    @http_only = args[:http_only] ||false
    @name      = args[:name]
    @value     = args[:value]
    @version   = args[:version]
    @created_at = DateTime.now
  end
  
  PARAM1 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE1})?\Z/
  # PARAM2 = /\A(#{PATTERN::TOKEN})(?:=#{PATTERN::VALUE2})?\Z/

  def self.from_set_cookie(request_uri, set_cookie_value)
    args = {}
    params=set_cookie_value.split(/;\s*/)
    params.each do |param|
      result = PARAM1.match param
      if (!result) 
        raise InvalidCookieError.new("Invalid cookie parameter in cookie '#{set_cookie_value}'")
      end
      key = result[1].upcase
      keyvalue = result[2] || result[3]
      case key
      when 'EXPIRES'
        args[:expires_at] = DateTime.parse(keyvalue)
      when 'DOMAIN'
        args[:domain] = keyvalue.downcase
      when 'PATH'
        args[:path] = keyvalue
      when 'SECURE'
        args[:secure] = true
      when 'HTTPONLY'
        args[:http_only] = true
      else
        args[:name] = key
        args[:value] = keyvalue
      end
    end
    args[:version] = 0
    Cookie.new(request_uri, args)
  end
  
  def to_s
    %Q^#{name}=#{value}#{if(domain) then "; domain=#{domain}" end}#{if (expires_at) then "; expires=#{expires_at}" end}#{if (path) then "; path=#{path}" end}#{if (secure) then "; secure" end }#{if (http_only) then "; HTTPOnly" end}^
  end
  
  def valid?
    raise InvalidCookieError.new("malformed cookie name '#{name}'") unless name =~ TOKEN
  end
end