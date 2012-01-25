module Sirportly
  class Request
    
    def self.request(path, data = {})
      req = self.new(path, :post)
      req.data = data
      req.make && req.success? ? req.output : false
    end
    
    attr_reader :path, :method
    attr_accessor :data
    
    def initialize(path, method = :get)
      @path = path
      @method = method
    end
    
    def success?
      @success || false
    end
    
    def output
      @output || nil
    end
    
    def make
      uri = URI.parse([Sirportly.domain, "api/v1", @path].join('/'))
      http_request = http_class.new(uri.request_uri)
      http_request.add_field("X-Auth-Token", Sirportly.token)
      http_request.add_field("X-Auth-Secret", Sirportly.secret)
      http_request.set_form_data(@data)
      
      http = Net::HTTP.new(uri.host, uri.port)
      
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      
      http_result = http.request(http_request)
      @output = JSON.parse(http_result.body)
      @success = case http_result
      when Net::HTTPSuccess
        true
      when Net::HTTPServiceUnavailable
        raise Sirportly::Errors::ServiceUnavailable
      when Net::HTTPForbidden, Net::HTTPUnauthorized
        raise Sirportly::Errors::AccessDenied, "Access Denied for '#{Sirportly.token}'"
      when Net::HTTPNotFound
        raise Sirportly::Errors::NotFound, "Not Found at #{uri.to_s}"
      when Net::HTTPClientError
        @output
      else
        raise Sirportly::Errors::CommunicationError, http_result.body
      end
      self
    end
    
    private
    
    def http_class  
      case @method
      when :post    then Net::HTTP::Post
      when :put     then Net::HTTP::Put
      when :delete  then Net::HTTP::Delete
      else
        Net::HTTP::Get
      end
    end
    
  end
end