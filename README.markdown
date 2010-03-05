CloudInfo
=======

Summary
-------
Assumes you're using engineyard's amazon could.  Allows you to use capistrano deployments to engineyard's amazon cloud without having to update your capistrano deploy.rb every time you add in instances in their gui.

Install
-------

<pre>
sudo gem install cloud_info --source http://gemcutter.org
</pre>

Set up your ~/.ey-cloud.yml file.
Set up your ~/.ssh/id-rsa-flex-key private key.

Usage
-------

in your deploy.rb

<pre>
require 'cloud_info'

task :production do
  ey_env_name = "prod1" # this is the environment name in EY's gui interface
  cloud_info = CloudInfo.new(ey_env_name, :private_key => "~/.ssh/id-rsa-flex-key")

  role :db, cloud_info.app_master, :primary => true
  # web and app slices
  cloud_info.apps.each do |info|
    role :web, info[1]
    role :app, info[1], :sphinx => true
  end

  # utility slices
  cloud_info.utils.each do |info|
    role :app, info[1], :sphinx => true
  end

  set :environment_database, Proc.new { production_database }
  set :user,          'deploy'
  set :runner,        'deploy'
  set :rails_env,     'production'
end
</pre>

To look at what the hosts contain use script/console.  cloud_info.apps, cloud_info.utils just holds a hash of keys and dns_names.

<pre>
./script/console

require "cloud_info"
cloud_info = CloudInfo.new("prod1")
pp cloud_info.apps
{
  "prod1_app0" => '123.456.789.123',
  "prod1_app1" => 'ec-123.456.789.123.whatever'
}

pp cloud_info.hosts # shows all hosts
{
  "prod1_app0" => '123.456.789.123', # app_master
  "prod1_app1" => 'ec-123.456.789.123.whatever', # app
  "prod1_db0" => 'ec-123.456.789.123.whatever', # db_master
  "prod1_db1" => 'ec-123.456.789.123.whatever', # db_slave
  "prod1_util0" => 'ec-123.456.789.123.whatever', # util instance, name util0
}
</pre>


Compatibility
-------------

Tested with Ruby 1.8.6.

Thanks
------
