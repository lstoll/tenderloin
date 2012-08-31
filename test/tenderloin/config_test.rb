require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ConfigTest < Test::Unit::TestCase
  context "resetting" do
    setup do
      Tenderloin::Config.run { |config| }
      Tenderloin::Config.execute!
    end

    should "return the same config object typically" do
      config = Tenderloin::Config.config
      assert config.equal?(Tenderloin::Config.config)
    end

    should "create a new object if cleared" do
      config = Tenderloin::Config.config
      Tenderloin::Config.reset!
      assert !config.equal?(Tenderloin::Config.config)
    end

    should "empty the runners" do
      assert !Tenderloin::Config.config_runners.empty?
      Tenderloin::Config.reset!
      assert Tenderloin::Config.config_runners.empty?
    end
  end

  context "accessing configuration" do
    setup do
      Tenderloin::Config.run { |config| }
      Tenderloin::Config.execute!
    end

    should "forward config to the class method" do
      assert_equal Tenderloin.config, Tenderloin::Config.config
    end
  end

  context "initializing" do
    teardown do
      Tenderloin::Config.instance_variable_set(:@config_runners, nil)
      Tenderloin::Config.instance_variable_set(:@config, nil)
    end

    should "not run the blocks right away" do
      obj = mock("obj")
      obj.expects(:foo).never
      Tenderloin::Config.run { |config| obj.foo }
      Tenderloin::Config.run { |config| obj.foo }
      Tenderloin::Config.run { |config| obj.foo }
    end

    should "run the blocks when execute! is ran" do
      obj = mock("obj")
      obj.expects(:foo).times(2)
      Tenderloin::Config.run { |config| obj.foo }
      Tenderloin::Config.run { |config| obj.foo }
      Tenderloin::Config.execute!
    end

    should "run the blocks with the same config object" do
      Tenderloin::Config.run { |config| assert config }
      Tenderloin::Config.run { |config| assert config }
      Tenderloin::Config.execute!
    end

    should "not be loaded, initially" do
      assert !Tenderloin::Config.config.loaded?
    end

    should "be loaded after running" do
      Tenderloin::Config.run {}
      Tenderloin::Config.execute!
      assert Tenderloin::Config.config.loaded?
    end
  end

  context "base class" do
    setup do
      @base = Tenderloin::Config::Base.new
    end

    should "forward [] access to methods" do
      @base.expects(:foo).once
      @base[:foo]
    end

    should "return a hash of instance variables" do
      data = { :foo => "bar", :bar => "baz" }

      data.each do |iv, value|
        @base.instance_variable_set("@#{iv}".to_sym, value)
      end

      result = @base.instance_variables_hash
      assert_equal data.length, result.length

      data.each do |iv, value|
        assert_equal value, result[iv]
      end
    end

    should "convert instance variable hash to json" do
      @json = mock("json")
      @iv_hash = mock("iv_hash")
      @iv_hash.expects(:to_json).once.returns(@json)
      @base.expects(:instance_variables_hash).returns(@iv_hash)
      assert_equal @json, @base.to_json
    end
  end

  context "chef config" do
    setup do
      @config = Tenderloin::Config::ChefConfig.new
      @config.json = "HEY"
    end

    should "not include the 'json' key in the config dump" do
      result = JSON.parse(@config.to_json)
      assert !result.has_key?("json")
    end
  end
end
