require 'rubygems'
require 'yaml'
require 'pp'
require File.join(%W/#{File.dirname(__FILE__)} cloud_info instances/)

class CloudInfo
  attr_reader :env_name
  def initialize(env_name, options = {})
    @env_name = env_name
    @options = options
    @cache_path = options[:cache_path] || 'config/cloud_info.yml'
  end
  
  # if a cache exist it uses it instead of finding the servers
  def hosts(use_cache = true)
    # check yaml file first
    puts "tung : #{@cache_path.inspect}"
    if use_cache and File.exist?(@cache_path)
      @hosts = (CloudInfo.read_yaml(@cache_path) || {})[env_name]
    end
    
    unless @hosts
      @instances = Instances.new(self, @options)
      @hosts = @instances.hosts
      
      if File.exist?(@cache_path)
        all_hosts = (CloudInfo.read_yaml(@cache_path) || {})
      else
        all_hosts = {}
      end
      all_hosts[env_name] = @hosts
      CloudInfo.write_yaml(@cache_path, all_hosts)
    end
    pp @hosts
    @hosts
  end
  
  def apps
    apps = hosts.select{|k,v| k =~ Regexp.new("#{@env_name}_app")}.sort {|a,b| a[0] <=> b[0] }
  end
  def app_master
    apps[0][1]
  end
  def utils
    utils = hosts.select{|k,v| k =~ Regexp.new("#{@env_name}_util")}.sort {|a,b| a[0] <=> b[0] }
  end
  
  def self.all_hosts(options = {})
    all_hosts = {}
    environments = Instances.ey_environments
    environments.each do |env|
      info = CloudInfo.new(env, options)
      hosts = info.hosts
      pp env
      pp hosts
      all_hosts.merge!(hosts)
    end
    all_hosts
  end
  
  def self.write_yaml(path, hosts)
    File.open(path, 'w') do |out|
      out.write(hosts.to_yaml)
    end
  end
  def self.read_yaml(path)
    YAML.load(IO.read(path))
  end
end