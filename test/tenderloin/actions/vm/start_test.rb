require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class StartActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Tenderloin::Actions::VM::Start)
    mock_config
  end

  context "sub-actions" do
    setup do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @default_order = [Tenderloin::Actions::VM::ForwardPorts, Tenderloin::Actions::VM::SharedFolders, Tenderloin::Actions::VM::Boot]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @mock_vm.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end
  end
end
