$testing = true
SPEC = File.dirname(__FILE__)
$:.unshift File.expand_path("#{SPEC}/../lib")

require 'cloud_info'
require 'pp'
require 'rubygems'
require 'mocha'

Spec::Runner.configure do |config|
  # config.mock_with :mocha
end

# For use with rspec textmate bundle
def debug(object)
  puts "<pre>"
  puts object.pretty_inspect.gsub('<', '&lt;').gsub('>', '&gt;')
  puts "</pre>"
end

