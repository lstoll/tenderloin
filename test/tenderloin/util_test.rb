require File.join(File.dirname(__FILE__), '..', 'test_helper')

class UtilTest < Test::Unit::TestCase
  class RegUtil
    extend Tenderloin::Util
  end

  context "erroring" do
    # TODO: Any way to stub Kernel.exit? Can't test nicely
    # otherwise
  end

  context "logger" do
    class OtherUtil
      extend Tenderloin::Util
    end

    setup do
      @config = Tenderloin::Config::Top.new
      @config.stubs(:loaded?).returns(true)
      @config.tenderloin.log_output = STDOUT
      Tenderloin::Config.stubs(:config).returns(@config)
      Tenderloin::Logger.reset_logger!
    end

    teardown do
      Tenderloin::Logger.reset_logger!
    end

    should "return a logger to nil if config is not loaded" do
      @config.expects(:loaded?).returns(false)
      logger = RegUtil.logger
      assert_nil logger.instance_variable_get(:@logdev)
    end

    should "return a logger using the configured output" do
      logger = RegUtil.logger
      logdev = logger.instance_variable_get(:@logdev)
      assert logger
      assert !logdev.nil?
      assert_equal STDOUT, logdev.dev
    end

    should "only instantiate a logger once" do
      Tenderloin::Logger.expects(:new).once.returns("GOOD")
      RegUtil.logger
      RegUtil.logger
    end

    should "be able to reset the logger" do
      Tenderloin::Logger.expects(:new).twice
      RegUtil.logger
      Tenderloin::Logger.reset_logger!
      RegUtil.logger
    end

    should "return the same logger across classes" do
      logger = RegUtil.logger
      other = OtherUtil.logger

      assert logger.equal?(other)
    end
  end
end
