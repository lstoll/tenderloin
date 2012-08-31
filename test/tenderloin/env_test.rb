require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  def mock_persisted_vm(returnvalue="foovm")
    filemock = mock("filemock")
    filemock.expects(:read).returns("foo")
    Tenderloin::VM.expects(:find).with("foo").returns(returnvalue)
    File.expects(:open).with(Tenderloin::Env.dotfile_path).once.yields(filemock)
    File.expects(:file?).with(Tenderloin::Env.dotfile_path).once.returns(true)
    Tenderloin::Env.load_vm!
  end

  setup do
    mock_config
    Tenderloin::Box.stubs(:find).returns("foo")
  end

  context "requiring a VM" do
    setup do
      Tenderloin::Env.stubs(:require_root_path)
      Tenderloin::Env.stubs(:error_and_exit)
    end

    should "require root path" do
      Tenderloin::Env.expects(:require_root_path).once
      Tenderloin::Env.require_persisted_vm
    end

    should "error and exit if no persisted VM was found" do
      assert_nil Tenderloin::Env.persisted_vm
      Tenderloin::Env.expects(:error_and_exit).once
      Tenderloin::Env.require_persisted_vm
    end

    should "return and continue if persisted VM is found" do
      mock_persisted_vm
      Tenderloin::Env.expects(:error_and_exit).never
      Tenderloin::Env.require_persisted_vm
    end
  end

  context "loading home directory" do
    setup do
      @home_dir = File.expand_path(Tenderloin.config.tenderloin.home)

      File.stubs(:directory?).returns(true)
      FileUtils.stubs(:mkdir_p)
    end

    should "create each directory if it doesn't exist" do
      create_seq = sequence("create_seq")
      File.stubs(:directory?).returns(false)
      Tenderloin::Env::HOME_SUBDIRS.each do |subdir|
        FileUtils.expects(:mkdir_p).with(File.join(@home_dir, subdir)).in_sequence(create_seq)
      end

      Tenderloin::Env.load_home_directory!
    end

    should "not create directories if they exist" do
      File.stubs(:directory?).returns(true)
      FileUtils.expects(:mkdir_p).never
      Tenderloin::Env.load_home_directory!
    end
  end

  context "loading config" do
    setup do
      @root_path = "/foo"
      Tenderloin::Env.stubs(:root_path).returns(@root_path)
      Tenderloin::Env.stubs(:box).returns(nil)
      File.stubs(:exist?).returns(false)
      Tenderloin::Config.stubs(:execute!)
      Tenderloin::Config.stubs(:reset!)
    end

    should "reset the configuration object" do
      Tenderloin::Config.expects(:reset!).once
      Tenderloin::Env.load_config!
    end

    should "load from the project root" do
      File.expects(:exist?).with(File.join(PROJECT_ROOT, "config", "default.rb")).once
      Tenderloin::Env.load_config!
    end

    should "load from the root path" do
      File.expects(:exist?).with(File.join(@root_path, Tenderloin::Env::ROOTFILE_NAME)).once
      Tenderloin::Env.load_config!
    end

    should "not load from the root path if nil" do
      Tenderloin::Env.stubs(:root_path).returns(nil)
      File.expects(:exist?).with(File.join(@root_path, Tenderloin::Env::ROOTFILE_NAME)).never
      Tenderloin::Env.load_config!
    end

    should "not load from the box directory if it is nil" do
      Tenderloin::Env.expects(:box).once.returns(nil)
      Tenderloin::Env.load_config!
    end

    should "load from the box directory if it is not nil" do
      dir = "foo"
      box = mock("box")
      box.stubs(:directory).returns(dir)
      Tenderloin::Env.expects(:box).twice.returns(box)
      File.expects(:exist?).with(File.join(dir, Tenderloin::Env::ROOTFILE_NAME)).once
      Tenderloin::Env.load_config!
    end

    should "load the files only if exist? returns true" do
      File.expects(:exist?).once.returns(true)
      Tenderloin::Env.expects(:load).once
      Tenderloin::Env.load_config!
    end

    should "not load the files if exist? returns false" do
      Tenderloin::Env.expects(:load).never
      Tenderloin::Env.load_config!
    end

    should "execute after loading" do
      File.expects(:exist?).once.returns(true)
      Tenderloin::Env.expects(:load).once
      Tenderloin::Config.expects(:execute!).once
      Tenderloin::Env.load_config!
    end
  end

  context "initial load" do
    test "load! should load the config and set the persisted_uid" do
      Tenderloin::Env.expects(:load_config!).once
      Tenderloin::Env.expects(:load_vm!).once
      Tenderloin::Env.expects(:load_root_path!).once
      Tenderloin::Env.expects(:load_home_directory!).once
      Tenderloin::Env.expects(:load_box!).once
      Tenderloin::Env.load!
    end
  end

  context "persisting the VM into a file" do
    setup do
      mock_config
    end

    test "should save it to the dotfile path" do
      vm = mock("vm")
      vm.stubs(:uuid).returns("foo")

      filemock = mock("filemock")
      filemock.expects(:write).with(vm.uuid)
      File.expects(:open).with(Tenderloin::Env.dotfile_path, 'w+').once.yields(filemock)
      Tenderloin::Env.persist_vm(vm)
    end
  end

  context "loading the UUID out from the persisted file" do
    setup do
      File.stubs(:file?).returns(true)
    end

    should "loading of the uuid from the dotfile" do
      mock_persisted_vm
      assert_equal 'foovm', Tenderloin::Env.persisted_vm
    end

    should "do nothing if the root path is nil" do
      File.expects(:open).never
      Tenderloin::Env.stubs(:root_path).returns(nil)
      Tenderloin::Env.load_vm!
    end

    should "do nothing if dotfile is not a file" do
      File.expects(:file?).returns(false)
      File.expects(:open).never
      Tenderloin::Env.load_vm!
    end

    should "uuid should be nil if dotfile didn't exist" do
      File.expects(:open).raises(Errno::ENOENT)
      Tenderloin::Env.load_vm!
      assert_nil Tenderloin::Env.persisted_vm
    end

    should "should build up the dotfile out of the root path and the dotfile name" do
      assert_equal File.join(Tenderloin::Env.root_path, Tenderloin.config.tenderloin.dotfile_name), Tenderloin::Env.dotfile_path
    end
  end

  context "loading the root path" do
    should "default the path to the pwd if nil" do
      @path = mock("path")
      @path.stubs(:to_s).returns("/")
      Pathname.expects(:new).with(Dir.pwd).returns(@path)
      Tenderloin::Env.load_root_path!(nil)
    end

    should "not default the path to pwd if its not nil" do
      @path = mock("path")
      @path.stubs(:to_s).returns("/")
      Pathname.expects(:new).never
      Tenderloin::Env.load_root_path!(@path)
    end

    should "should walk the parent directories looking for rootfile" do
      paths = [
        Pathname.new("/foo/bar/baz"),
        Pathname.new("/foo/bar"),
        Pathname.new("/foo")
      ]

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with("#{path}/#{Tenderloin::Env::ROOTFILE_NAME}").returns(false).in_sequence(search_seq)
      end

      assert !Tenderloin::Env.load_root_path!(paths.first)
    end

    should "return false if not found" do
      path = Pathname.new("/")
      assert !Tenderloin::Env.load_root_path!(path)
    end

    should "return false if not found on windows-style root" do
      path = Pathname.new("C:.")
      assert !Tenderloin::Env.load_root_path!(path)
    end

    should "should set the path for the rootfile" do
      path = "/foo"
      File.expects(:exist?).with("#{path}/#{Tenderloin::Env::ROOTFILE_NAME}").returns(true)

      assert Tenderloin::Env.load_root_path!(Pathname.new(path))
      assert_equal path, Tenderloin::Env.root_path
    end
  end

  context "home directory paths" do
    should "return the expanded config for `home_path`" do
      assert_equal File.expand_path(Tenderloin.config.tenderloin.home), Tenderloin::Env.home_path
    end

    should "return the home_path joined with tmp for a tmp path" do
      @home_path = "foo"
      Tenderloin::Env.stubs(:home_path).returns(@home_path)
      assert_equal File.join(@home_path, "tmp"), Tenderloin::Env.tmp_path
    end

    should "return the boxes path" do
      @home_path = "foo"
      Tenderloin::Env.stubs(:home_path).returns(@home_path)
      assert_equal File.join(@home_path, "boxes"), Tenderloin::Env.boxes_path
    end
  end

  context "loading box" do
    setup do
      @box = mock("box")

      Tenderloin::Env.stubs(:load_config!)
      Tenderloin::Env.stubs(:root_path).returns("foo")
    end

    should "do nothing if the root path is nil" do
      Tenderloin::Box.expects(:find).never
      Tenderloin::Env.stubs(:root_path).returns(nil)
      Tenderloin::Env.load_vm!
    end

    should "not load the box if its not set" do
      mock_config do |config|
        config.vm.box = nil
      end

      Tenderloin::Box.expects(:find).never
      Tenderloin::Env.load_box!
    end

    should "set the box to what is found by the Box class" do
      Tenderloin::Box.expects(:find).with(Tenderloin.config.vm.box).once.returns(@box)
      Tenderloin::Env.load_box!
      assert @box.equal?(Tenderloin::Env.box)
    end

    should "load the config if a box is loaded" do
      Tenderloin::Env.expects(:load_config!).once
      Tenderloin::Box.expects(:find).returns(@box)
      Tenderloin::Env.load_box!
    end
  end

  context "requiring boxes" do
    setup do
      Tenderloin::Env.stubs(:require_root_path)
      Tenderloin::Env.stubs(:error_and_exit)
    end

    should "require root path" do
      Tenderloin::Env.expects(:require_root_path).once
      Tenderloin::Env.require_box
    end

    should "error and exit if no box is found" do
      mock_config do |config|
        config.vm.box = nil
      end

      Tenderloin::Env.expects(:box).returns(nil)
      Tenderloin::Env.expects(:error_and_exit).once.with() do |msg|
        assert msg =~ /no base box was specified/i
        true
      end
      Tenderloin::Env.require_box
    end

    should "error and exit if box is specified but doesn't exist" do
      mock_config do |config|
        config.vm.box = "foo"
      end

      Tenderloin::Env.expects(:box).returns(nil)
      Tenderloin::Env.expects(:error_and_exit).once.with() do |msg|
        assert msg =~ /does not exist/i
        true
      end
      Tenderloin::Env.require_box
    end
  end

  context "requiring root_path" do
    should "error and exit if no root_path is set" do
      Tenderloin::Env.expects(:root_path).returns(nil)
      Tenderloin::Env.expects(:error_and_exit).once
      Tenderloin::Env.require_root_path
    end

    should "not error and exit if root_path is set" do
      Tenderloin::Env.expects(:root_path).returns("foo")
      Tenderloin::Env.expects(:error_and_exit).never
      Tenderloin::Env.require_root_path
    end
  end
end
