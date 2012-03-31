require 'helper'

class TestEmXmlrpcClient < Test::Unit::TestCase

  def test_em_http
    host = "localhost"
    path = "api/v2/xmlrpc"
    stub_request(:post, "http://#{host}/#{path}").to_return(File.read("test/data/response"))
    expected = {"zoneId"=>55, "publisherId"=>6, "zoneName"=>"Telegraph ATW", "type"=>0, "width"=>150, "height"=>150, "capping"=>0, "sessionCapping"=>0, "block"=>0, "comments"=>"", "append"=>"", "prepend"=>""}

    EM.run do
      Fiber.new do
        client = XMLRPC::Client.new2("http://#{host}/#{path}")
        mock.proxy(client).do_rpc_em_http(anything, anything, anything)
        mock(client).do_rpc_net_http.never
        actual = client.call("ox.getZone", "phpads4e32f100507466.86347358", 54)
        assert_equal expected, actual
        EM.stop
      end.resume
    end
  end

  def test_net_http
    host = "localhost"
    path = "api/v2/xmlrpc"
    stub_request(:post, "http://#{host}/#{path}").to_return(File.read("test/data/response"))
    expected = {"zoneId"=>55, "publisherId"=>6, "zoneName"=>"Telegraph ATW", "type"=>0, "width"=>150, "height"=>150, "capping"=>0, "sessionCapping"=>0, "block"=>0, "comments"=>"", "append"=>"", "prepend"=>""}

    client = XMLRPC::Client.new2("http://#{host}/#{path}")
    mock(client).do_rpc_em_http.never
    mock.proxy(client).do_rpc_net_http(anything, anything, anything)
    actual = client.call("ox.getZone", "phpads4e32f100507466.86347358", 54)
    assert_equal expected, actual
  end

end
