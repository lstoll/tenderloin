require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class BootActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Tenderloin::Actions::VM::Boot)
    @mock_vm.stubs(:invoke_callback)
    mock_config
  end

  context "execution" do
    should "invoke the 'boot' around callback" do
      boot_seq = sequence("boot_seq")
      @mock_vm.expects(:invoke_around_callback).with(:boot).once.in_sequence(boot_seq).yields
      @action.expects(:boot).in_sequence(boot_seq)
      @action.expects(:wait_for_boot).returns(true).in_sequence(boot_seq)
      @action.execute!
    end

    should "error and exit if the bootup failed" do
      fail_boot_seq = sequence("fail_boot_seq")
      @action.expects(:boot).once.in_sequence(fail_boot_seq)
      @action.expects(:wait_for_boot).returns(false).in_sequence(fail_boot_seq)
      @action.expects(:error_and_exit).once.in_sequence(fail_boot_seq)
      @action.execute!
    end
  end

  context "booting" do
    should "start the VM in headless mode" do
      @vm.expects(:start).with(:headless, true).once
      @action.boot
    end
  end

  context "waiting for boot" do
    should "repeatedly ping the SSH port and return false with no response" do
      seq = sequence('pings')
      Tenderloin::SSH.expects(:up?).times(Tenderloin.config[:ssh][:max_tries].to_i - 1).returns(false).in_sequence(seq)
      Tenderloin::SSH.expects(:up?).once.returns(true).in_sequence(seq)
      assert @action.wait_for_boot(0)
    end

    should "ping the max number of times then just return" do
      Tenderloin::SSH.expects(:up?).times(Tenderloin.config[:ssh][:max_tries].to_i).returns(false)
      assert !@action.wait_for_boot(0)
    end
  end

  context "callbacks" do
    should "setup the root directory shared folder" do
      expected = ["tenderloin-root", Tenderloin::Env.root_path, Tenderloin.config.vm.project_directory]
      assert_equal expected, @action.collect_shared_folders
    end
  end
end
