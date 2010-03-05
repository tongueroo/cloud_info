require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe CloudInfo::Instances do
  describe "with-cache" do
    before(:each) do
    end

    it "standard usage" do
      @info = CloudInfo.new("prod_br", :private_key => "~/.ssh/id_rsa-flex-br")
      @info.hosts.class.should == Hash
      # pp @info.hosts
    end

    # it "standard usage" do
    #   @info = CloudInfo.new("beta", :private_key => "~/.ssh/id_rsa-flex-br")
    #   @info.hosts.class.should == Hash
    #   # pp @info.hosts
    # end
  end

  # describe "no-cache" do
  #   before(:each) do
  #     File.delete("config/cloud_info.yml") if File.exist?("config/cloud_info.yml")
  #   end
  # 
  #   it "standard usage" do
  #     @info = CloudInfo.new("prod_br", :private_key => "~/.ssh/id_rsa-flex-br")
  #     @info.hosts.class.should == Hash
  #     # pp @info.hosts
  #   end
  #   # 
  #   # it "tung" do
  #   #   pp CloudInfo::Instances.new(@info).aws_instances.first
  #   # end
  # 
  #   # it "ey_environments" do
  #   #   pp CloudInfo::Instances.ey_environments
  #   # end
  #   # 
  #   # it "all_hosts" do
  #   #   all_hosts = CloudInfo.all_hosts(:private_key => "~/.ssh/id_rsa-flex-br")
  #   #   pp all_hosts
  #   # end
  # 
  #   it "write and read yaml" do
  #     hosts = {"whatever" => "test"}
  #     path = File.join(File.dirname(__FILE__),"fixtures","cloud_info.yml")
  #     CloudInfo.write_yaml(path, hosts)
  #     yaml = CloudInfo.read_yaml(path)
  #     yaml["whatever"].should == "test"
  #   end
  # end
  
end