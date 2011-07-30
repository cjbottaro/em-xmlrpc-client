require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'eventmachine'
require 'em-http'
require 'webmock/test_unit' # This needs to come after requiring 'em-http'.
require 'rr'
require 'em-xmlrpc-client'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end
