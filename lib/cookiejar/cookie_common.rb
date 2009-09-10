module CookieJar
  class CookieError < StandardError; end
  class InvalidCookieError < CookieError; 
    attr_reader :messages
    def initialize message
     if message.is_a? Array
       @messages = message
       message = message.join ', '
     end
     super(message)
    end
  end
end