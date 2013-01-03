require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class UpActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Tenderloin::Actions::VM::Up)
    mock_config
  end

  context "sub-actions" do
    setup do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @default_order = [Tenderloin::Actions::VM::Import, Tenderloin::Actions::VM::ForwardPorts, Tenderloin::Actions::VM::SharedFolders, Tenderloin::Actions::VM::Boot]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "raise an ActionException if a dotfile exists but is not a file" do
      File.expects(:file?).with(Tenderloin::Env.dotfile_path).returns(false)
      assert_raises(Tenderloin::Actions::ActionException) {
        @action.prepare
      }
    end

    should "not raise an ActionException if dotfile doesn't exist" do
      setup_action_expectations
      File.stubs(:exist?).returns(false)
      assert_nothing_raised { @action.prepare }
    end

    should "not raise an ActionException if dotfile exists but is a file" do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      setup_action_expectations
      assert_nothing_raised { @action.prepare }
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add in the provisioning step if enabled" do
      mock_config do |config|
        config.chef.enabled = true
      end

      @default_order.push(Tenderloin::Actions::VM::Provision)
      setup_action_expectations
      @action.prepare
    end

    should "add in the action to move hard drive if config is set" do
      mock_config do |config|
        File.expects(:directory?).with("foo").returns(true)
        config.vm.hd_location = "foo"
      end

      @default_order.insert(0, Tenderloin::Actions::VM::MoveHardDrive)
      setup_action_expectations
      @action.prepare
    end
  end

  context "callbacks" do
    should "call persist and mac address setup after import" do
      boot_seq = sequence("boot")
      @action.expects(:persist).once.in_sequence(boot_seq)
      @action.expects(:setup_mac_address).once.in_sequence(boot_seq)
      @action.after_import
    end
  end

  context "persisting" do
    should "persist the VM with Env" do
      @vm.stubs(:uuid)
      Tenderloin::Env.expects(:persist_vm).with(@vm).once
      @action.persist
    end
  end

  context "setting up MAC address" do
    should "match the mac address with the base" do
      nic = mock("nic")
      nic.expects(:macaddress=).once

      @vm.expects(:nics).returns([nic]).once
      @vm.expects(:save).with(true).once

      @action.setup_mac_address
    end
  end

  context "booting without provisioning" do
    should "not add the provision task to the expected sequence" do
      mock_vm, vm, action = mock_action(Tenderloin::Actions::VM::Up, :no_provision)

      mock_config do |config|
        config.chef.enabled = true
      end

      action.should_not be_provision_enabled
    end
  end
end
