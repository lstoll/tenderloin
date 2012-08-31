require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ProvisionActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Tenderloin::Actions::VM::Provision)

    Tenderloin::SSH.stubs(:execute)
    Tenderloin::SSH.stubs(:upload!)

    mock_config
  end

  context "shared folders" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Tenderloin.config.chef.cookbooks_path, Tenderloin::Env.root_path).returns("foo")
      @action.expects(:cookbooks_path).returns("bar")
      assert_equal ["tenderloin-provisioning", "foo", "bar"], @action.collect_shared_folders
    end
  end

  context "cookbooks path" do
    should "return the proper cookbook path" do
      cookbooks_path = File.join(Tenderloin.config.chef.provisioning_path, "cookbooks")
      assert_equal cookbooks_path, @action.cookbooks_path
    end
  end

  context "permissions on provisioning folder" do
    should "chown the folder to the ssh user" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo chown #{Tenderloin.config.ssh.username} #{Tenderloin.config.chef.provisioning_path}")
      Tenderloin::SSH.expects(:execute).yields(ssh)
      @action.chown_provisioning_folder
    end
  end

  context "generating and uploading json" do
    def assert_json
      Tenderloin::SSH.expects(:upload!).with do |json, path|
        data = JSON.parse(json.read)
        yield data
        true
      end

      @action.setup_json
    end

    should "merge in the extra json specified in the config" do
      Tenderloin.config.chef.json = { :foo => "BAR" }
      assert_json do |data|
        assert_equal "BAR", data["foo"]
      end
    end

    should "add the directory as a special case to the JSON" do
      assert_json do |data|
        assert_equal Tenderloin.config.vm.project_directory, data["tenderloin"]["directory"]
      end
    end

    should "add the config to the JSON" do
      assert_json do |data|
        assert_equal Tenderloin.config.vm.project_directory, data["tenderloin"]["config"]["vm"]["project_directory"]
      end
    end

    should "upload a StringIO to dna.json" do
      StringIO.expects(:new).with(anything).returns("bar")
      File.expects(:join).with(Tenderloin.config.chef.provisioning_path, "dna.json").once.returns("baz")
      Tenderloin::SSH.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end

  context "generating and uploading chef solo configuration file" do
    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
file_cache_path "#{Tenderloin.config.chef.provisioning_path}"
cookbook_path "#{@action.cookbooks_path}"
config

      StringIO.expects(:new).with(expected_config).once
      @action.setup_solo_config
    end

    should "upload this file as solo.rb to the provisioning folder" do
      @action.expects(:cookbooks_path).returns("cookbooks")
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(Tenderloin.config.chef.provisioning_path, "solo.rb").once.returns("bar")
      Tenderloin::SSH.expects(:upload!).with("foo", "bar").once
      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    should "cd into the provisioning directory and run chef solo" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{Tenderloin.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json").once
      Tenderloin::SSH.expects(:execute).yields(ssh)
      @action.run_chef_solo
    end
  end
end
