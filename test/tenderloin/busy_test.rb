require File.join(File.dirname(__FILE__), '..', 'test_helper')

class BusyTest < Test::Unit::TestCase
  context "waiting for not busy" do
    setup do
      Tenderloin::Busy.reset_trap_thread!
    end

    should "run in a thread" do
      Thread.expects(:new).once.returns(nil)
      Tenderloin::Busy.wait_for_not_busy
    end

    should "not start a thread multiple times" do
      Thread.expects(:new).once.returns("foo")
      Tenderloin::Busy.wait_for_not_busy
    end
  end

  context "during an action in a busy block" do
    should "report as busy" do
      Tenderloin.busy do
        # Inside the block Tenderloin.busy? should be true
        assert Tenderloin.busy?
      end

      #After the block finishes Tenderloin.busy? should be false
      assert !Tenderloin.busy?
    end

    should "set busy to false upon exception and reraise the error" do
      assert_raise Exception do
        Tenderloin.busy do
          assert Tenderloin.busy?
          raise Exception
        end
      end

      assert !Tenderloin.busy?
    end

    should "complete the trap thread even if an exception occurs" do
      trap_thread = mock("trap_thread")
      trap_thread.expects(:join).once
      Tenderloin::Busy.stubs(:trap_thread).returns(trap_thread)

      assert_raise Exception do
        Tenderloin.busy do
          raise Exception
        end
      end
    end

    should "report busy to the outside world regardless of thread" do
      Thread.new do
        Tenderloin.busy do
          sleep(2)
        end
      end
      # Give the thread time to start
      sleep(1)

      # While the above thread is executing tenderloin should be busy
      assert Tenderloin.busy?
    end

    should "run the action in a new thread" do
      runner_thread = nil
      Tenderloin.busy do
        runner_thread = Thread.current
      end

      assert_not_equal Thread.current, runner_thread
    end

    should "trap INT" do
      trap_seq = sequence("trap_seq")
      Signal.expects(:trap).with("INT", anything).once.in_sequence(trap_seq)
      Signal.expects(:trap).with("INT", "DEFAULT").once.in_sequence(trap_seq)
      Tenderloin.busy do; end
    end
  end
end
