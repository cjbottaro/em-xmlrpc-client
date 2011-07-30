require "xmlrpc/client"

module XMLRPC
  class Client

    def initialize(host=nil, path=nil, port=nil, proxy_host=nil, proxy_port=nil,
                   user=nil, password=nil, use_ssl=nil, timeout=nil)

      @http_header_extra = nil
      @http_last_response = nil
      @cookie = nil

      @host       = host || "localhost"
      @path       = path || "/RPC2"
      @proxy_host = proxy_host
      @proxy_port = proxy_port
      @proxy_host ||= 'localhost' if @proxy_port != nil
      @proxy_port ||= 8080 if @proxy_host != nil
      @use_ssl    = use_ssl || false
      @timeout    = timeout || 30

      if use_ssl
        require "net/https"
        @port = port || 443
      else
        @port = port || 80
      end

      @user, @password = user, password

      set_auth

      # convert ports to integers
      @port = @port.to_i if @port != nil
      @proxy_port = @proxy_port.to_i if @proxy_port != nil

      if defined?(EM) and EM.reactor_running?
        require "em-http"
        require "ostruct"
        require "fiber"
      else
        # HTTP object for synchronous calls
        Net::HTTP.version_1_2
        @http = Net::HTTP.new(@host, @port, @proxy_host, @proxy_port)
        @http.use_ssl = @use_ssl if @use_ssl
        @http.read_timeout = @timeout
        @http.open_timeout = @timeout
      end

      @parser = nil
      @create = nil
    end

    def do_rpc(request, async=false)
      header = {
       "User-Agent"     =>  USER_AGENT,
       "Content-Type"   => "text/xml; charset=utf-8",
       "Content-Length" => request.size.to_s,
       "Connection"     => (async ? "close" : "keep-alive")
      }

      header["Cookie"] = @cookie        if @cookie
      header.update(@http_header_extra) if @http_header_extra

      if @auth != nil
        # add authorization header
        header["Authorization"] = @auth
      end

      @http_last_response = nil

      if defined?(EM) and EM.reactor_running?
        resp = do_rpc_em_http(async, request, header)
      else
        resp = do_rpc_net_http(async, request, header)
      end

      @http_last_response = resp

      data = resp.body

      if resp.code == "401"
        # Authorization Required
        raise "Authorization failed.\nHTTP-Error: #{resp.code} #{resp.message}"
      elsif resp.code[0,1] != "2"
        raise "HTTP-Error: #{resp.code} #{resp.message}"
      end

      ct = parse_content_type(resp["Content-Type"]).first
      if ct != "text/xml"
        if ct == "text/html"
          raise "Wrong content-type (received '#{ct}' but expected 'text/xml'): \n#{data}"
        else
          raise "Wrong content-type (received '#{ct}' but expected 'text/xml')"
        end
      end

      expected = resp["Content-Length"] || "<unknown>"
      if data.nil? or data.size == 0
        raise "Wrong size. Was #{data.size}, should be #{expected}"
      elsif expected != "<unknown>" and expected.to_i != data.size and resp["Transfer-Encoding"].nil?
        raise "Wrong size. Was #{data.size}, should be #{expected}"
      end

      set_cookies = resp.get_fields("Set-Cookie")
      if set_cookies and !set_cookies.empty?
        require 'webrick/cookie'
        @cookie = set_cookies.collect do |set_cookie|
          cookie = WEBrick::Cookie.parse_set_cookie(set_cookie)
          WEBrick::Cookie.new(cookie.name, cookie.value).to_s
        end.join("; ")
      end

      return data
    end

    def timeout=(new_timeout)
      @timeout = new_timeout
      unless defined?(EM) and EM.reactor_running?
        @http.read_timeout = @timeout
        @http.open_timeout = @timeout
      end
    end

    def do_rpc_em_http(async, request, header)
      fiber = Fiber.current
      http = EM::HttpRequest.new("http://#{@host}:#{@port}#{@path}").post :body => request, :timeout => @timeout
      http.callback{ fiber.resume }
      http.errback do
        # Unfortunately, we can't determine exactly what the error is using EventMachine < 1.0.
        error = RuntimeError.new("connection or timeout error")
        fiber.resume(error)
      end

      e = Fiber.yield and raise(e)

      # Ducktype our response object.
      resp = OpenStruct.new :code     => http.response_header.http_status.to_s,
                            :message  => http.response_header.http_reason,
                            :header   => http.response_header.to_hash,
                            :body     => http.response.to_s

      resp.header["Content-Type"]      = resp.header["CONTENT_TYPE"]
      resp.header["Content-Length"]    = resp.header["CONTENT_LENGTH"]
      resp.header["Transfer-Encoding"] = resp.header["TRANSFER_ENCODING"]
      resp.header["Set-Cookie"]        = resp.header["SET_COOKIE"]

      def resp.[](name)
        header[name]
      end
      def resp.get_fields(name)
        value = header[name]
        value and [value].flatten
      end
      
      resp
    end

    def do_rpc_net_http(async, request, header)
      resp = nil

      if async
        # use a new HTTP object for each call
        Net::HTTP.version_1_2
        http = Net::HTTP.new(@host, @port, @proxy_host, @proxy_port)
        http.use_ssl = @use_ssl if @use_ssl
        http.read_timeout = @timeout
        http.open_timeout = @timeout

        # post request
        http.start {
          resp = http.post2(@path, request, header)
        }
      else
        # reuse the HTTP object for each call => connection alive is possible
        # we must start connection explicitely first time so that http.request
        # does not assume that we don't want keepalive
        @http.start if not @http.started?

        # post request
        resp = @http.post2(@path, request, header)
      end
      
      resp
    end
    
  end
end
