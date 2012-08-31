require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ReloadActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Tenderloin::Actions::VM::Reload)
    mock_config
  end

  context "sub-actions" do
    setup do
      @default_order = [Tenderloin::Actions::VM::ForwardPorts, Tenderloin::Actions::VM::SharedFolders, Tenderloin::Actions::VM::Boot]
      @vm.stubs(:running?).returns(false)
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @runner.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "halt if the VM is running" do
      @vm.expects(:running?).returns(true)
      @default_order.unshift(Tenderloin::Actions::VM::Halt)
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
  end
end
