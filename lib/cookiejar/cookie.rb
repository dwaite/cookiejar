require 'date'

class Cookie
  attr_accessor :name, :value
  attr_accessor :created_at
  attr_accessor :expires
  attr_accessor :domain, :path
  attr_accessor :secure, :http_only
#  attr_accessor :version
#  attr_accessor :comment, :comment_url
#  attr_accessor :discard
#  attr_accessor :ports
  
  TwoDotDomains = /\.(com|edu|net|mil|gov|int|org)/
  

  def expires_at
    if expiry.is_a? DateTime
      expiry
    else
      DateTime.now.
  end
      
  def initialize(args)
    @domain = nil
    @expires_at = nil
    @path = '/'
    @secure = false
    @http_only = false

    @created_at = DateTime.now

    args.each do |arg|
      self.send("#{arg[0]}=".to_sym, arg[1])
    end
  end
  
  def self.parse(set_cookie_value)
    args = {}
    params=set_cookie_value.split(/;\s*/)
    print params
    params.each do |param|
      result = /^([^=]+)(=(.*$))?/.match param
      key = result[1].upcase
      keyvalue = result[3]
      case key
      when 'EXPIRES'
        args[:expires_at] = DateTime.parse(keyvalue)
      when 'DOMAIN'
        args[:domain] = keyvalue.upcase
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
    Cookie.new(args)
  end
  
  def valid?
    
  end
  
  def to_s
    %Q^#{name}=#{value}#{if(domain) then "; domain=#{domain}" end}#{if (expires_at) then "; expires=#{expires_at}" end}#{if (path) then "; path=#{path}" end}#{if (secure) then "; secure" end }#{if (http_only) then "; HTTPOnly" end}^
  end
end