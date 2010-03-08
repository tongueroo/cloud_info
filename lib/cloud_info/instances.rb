require 'right_aws'
require 'net/ssh'
require 'yaml'
require 'json'

class CloudInfo
  class Instances
    attr_accessor :user, :private_key, :servers, :sessions
    
    def initialize(cloud_info, options = {})
      @cloud_info = cloud_info
      @home_dir = ENV['HOME']
      @user = "root"  # TODO: move out
      @private_key = options[:private_key] # TODO: move out
      
      @ey_cloud = "#{@home_dir}/.ey-cloud.yml"
      unless File.exist?(@ey_cloud)
        warn("You need to have an ~/.ey-cloud.yml file")
        exit(1)
      end
      @config = YAML.load(IO.read(@ey_cloud))
      
      @servers = {}
      @sessions = []
      @ec2 = setup_ec2
    end
    
    def setup_ec2
      RightAws::Ec2.new(@config[:aws_secret_id], @config[:aws_secret_key])
    end
    
    def instances_in_group(group_id)
      aws_instances.select {|x| x[:aws_groups].include?(group_id) }
    end
    
    # only the instances for the env
    def instances
      instance_ids = ey_instances(@cloud_info.env_name)
      group_id = aws_group_for_instance_id(instance_ids.first)
      instances = instances_in_group(group_id)
      instances
    end
    
    def connect_to_servers
      thread = Thread.current
      hosts_with_blanks = instances.select{|i| i[:aws_state] == 'running'}.collect {|i| i[:dns_name]}
      hosts = hosts_with_blanks.select{|i| i[:dns_name] != ""}
      if hosts_with_blanks.size != hosts.size
        puts "WARNING: some hosts do not have dns_name's yet, amazon is not yet ready"
      end
      
      threads = hosts.collect do |host|
        Thread.new {
          @sessions << Net::SSH.start(host, @user, {:keys => @private_key})
          @sessions
        }
      end
      threads.collect {|t| t.join}
    end
    
    def build_server_infos
      return if @built
      execute_on_servers do |ssh|
        @servers[ssh.host] ||= {}
        dna_json = ssh.exec!("cat /etc/chef/dna.json")
        @servers[ssh.host]["dna"] = JSON.parse(dna_json)
      end
      @built = true
    end
    
    def execute_on_servers
      connect_to_servers
      threads = []
      sessions.each do |ssh|
        threads << Thread.new {
          yield(ssh)
        }
      end
      threads.collect{|t| t.join}
    end
    
    # builds up the hosts hash
    # TODO: move out
    # looks like this:
    # {"prod_br_app0"=>"123.456.789.123",
    #  "prod_br_util0"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_memcached0"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_util1"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_memcached1"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_app1"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_app2"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_app3"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_db0"=>"ec2-123.456.789.123.compute-1.amazonaws.com",
    #  "prod_br_db1"=>"ec2-123.456.789.123.compute-1.amazonaws.com"}
    def hosts
      build_server_infos
      h = {}
      counters = Hash.new(0)
      servers.each do |host, v|
        node = v["dna"]
        instance_role = node["instance_role"]
        env_name = @cloud_info.env_name
        
        case instance_role
        when "app_master"
          h["#{env_name}_app0"] = node["master_app_server"]["public_ip"]
        when "solo"
          h["#{env_name}_app0"] = host
        when "app"
          h["#{env_name}_app#{counters[:app] += 1}"] = host
        when "util"
          if node["name"] =~ /util/
            h["#{env_name}_#{node["name"]}"] = host
            counters[:util] += 1
          elsif
            h["#{env_name}_#{node["name"]}"] = host
            counters[:memcached] += 1
          end
        when "db_master"
          h["#{env_name}_db0"] = host
        when "db_slave"
          h["#{env_name}_db#{counters[:db] += 1}"] = host
        end
      end
      h
    end
    
    module Aws
      def aws_instances
        @@aws_instances ||= @ec2.describe_instances
      end

      def aws_groups
        @@aws_groups ||= aws_instances.collect{|x| x[:aws_groups]}.flatten.uniq
      end

      def aws_group_for_instance_id(instance_id)
        instance = aws_instances.find{|x| x[:aws_instance_id] == instance_id}
        aws_group = instance[:aws_groups].first
      end
    end
    include Aws
    
    def self.ey_recipes
      @@ey_recipes ||= `ey-recipes`
    end
    def ey_recipes
      self.class.ey_recipes
    end
    
    def self.ey_environments
      out = ey_recipes
      environments = out.split("\n").grep(/env/).collect {|x| x =~ /env\: (\w+) / ; $1 }
    end
    def ey_environments
      self.class.ey_environments
    end
    
    def ey_instances(env_name = nil)
      instance_ids = []
      out = ey_recipes
      lines = out.split("\n")
      line_with_instances = false
      lines.each do |line|
        if line_with_instances
          md = line.match(/\[(.*)\]/)
          list = md[1]
          instance_ids = list.split(",").collect{|x| x.gsub('"','').strip}
          break
        end
        if line =~ Regexp.new(env_name)
          line_with_instances = true # next line will have the instances info on it
        end
      end
      instance_ids
    end
    
  end
end

