require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CommandsTest < Test::Unit::TestCase
  setup do
    Tenderloin::Env.stubs(:load!)

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)
    Tenderloin::Env.stubs(:persisted_vm).returns(@persisted_vm)
    Tenderloin::Env.stubs(:require_persisted_vm)
  end

  context "init" do
    setup do
      FileUtils.stubs(:cp)
      @rootfile_path = File.join(Dir.pwd, Tenderloin::Env::ROOTFILE_NAME)
      @template_path = File.join(PROJECT_ROOT, "templates", Tenderloin::Env::ROOTFILE_NAME)
    end

    should "error and exit if a rootfile already exists" do
      File.expects(:exist?).with(@rootfile_path).returns(true)
      Tenderloin::Commands.expects(:error_and_exit).once
      Tenderloin::Commands.init
    end

    should "copy the templated rootfile to the current path" do
      File.expects(:exist?).with(@rootfile_path).returns(false)
      FileUtils.expects(:cp).with(@template_path, @rootfile_path).once
      Tenderloin::Commands.init
    end
  end

  context "up" do
    setup do
      Tenderloin::Env.stubs(:persisted_vm).returns(nil)
      Tenderloin::VM.stubs(:execute!)
      Tenderloin::Env.stubs(:require_box)
    end

    should "require load the environment" do
      Tenderloin::Env.expects(:load!).once
      Tenderloin::Commands.up
    end

    should "require a box" do
      Tenderloin::Env.expects(:require_box).once
      Tenderloin::Commands.up
    end

    should "call the up action on VM if it doesn't exist" do
      Tenderloin::VM.expects(:execute!).with(Tenderloin::Actions::VM::Up).once
      Tenderloin::Commands.up
    end

    should "call start on the persisted vm if it exists" do
      Tenderloin::Env.stubs(:persisted_vm).returns(@persisted_vm)
      @persisted_vm.expects(:start).once
      Tenderloin::VM.expects(:execute!).never
      Tenderloin::Commands.up
    end
  end

  context "down" do
    setup do
      @persisted_vm.stubs(:destroy)
    end

    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.down
    end

    should "destroy the persisted VM and the VM image" do
      @persisted_vm.expects(:destroy).once
      Tenderloin::Commands.down
    end
  end

  context "reload" do
    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.reload
    end

    should "call the `reload` action on the VM" do
      @persisted_vm.expects(:execute!).with(Tenderloin::Actions::VM::Reload).once
      Tenderloin::Commands.reload
    end
  end

  context "ssh" do
    setup do
      Tenderloin::SSH.stubs(:connect)
    end

    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.ssh
    end

    should "connect to SSH" do
      Tenderloin::SSH.expects(:connect).once
      Tenderloin::Commands.ssh
    end
  end

  context "halt" do
    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.halt
    end

    should "call the `halt` action on the VM" do
      @persisted_vm.expects(:execute!).with(Tenderloin::Actions::VM::Halt).once
      Tenderloin::Commands.halt
    end
  end

  context "suspend" do
    setup do
      @persisted_vm.stubs(:suspend)
      @persisted_vm.stubs(:saved?).returns(false)
    end

    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.suspend
    end

    should "suspend the VM" do
      @persisted_vm.expects(:suspend).once
      Tenderloin::Commands.suspend
    end
  end

  context "resume" do
    setup do
      @persisted_vm.stubs(:resume)
      @persisted_vm.stubs(:saved?).returns(true)
    end

    should "require a persisted VM" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.resume
    end

    should "save the state of the VM" do
      @persisted_vm.expects(:resume).once
      Tenderloin::Commands.resume
    end
  end

  context "package" do
    setup do
      @persisted_vm.stubs(:package)
      @persisted_vm.stubs(:powered_off?).returns(true)
    end

    should "require a persisted vm" do
      Tenderloin::Env.expects(:require_persisted_vm).once
      Tenderloin::Commands.package
    end

    should "error and exit if the VM is not powered off" do
      @persisted_vm.stubs(:powered_off?).returns(false)
      Tenderloin::Commands.expects(:error_and_exit).once
      @persisted_vm.expects(:package).never
      Tenderloin::Commands.package
    end

    should "call package on the persisted VM" do
      @persisted_vm.expects(:package).once
      Tenderloin::Commands.package
    end

    should "pass the out path and include_files to the package method" do
      out_path = mock("out_path")
      include_files = mock("include_files")
      @persisted_vm.expects(:package).with(out_path, include_files).once
      Tenderloin::Commands.package(out_path, include_files)
    end

    should "default to an empty array when not include_files are specified" do
      out_path = mock("out_path")
      @persisted_vm.expects(:package).with(out_path, []).once
      Tenderloin::Commands.package(out_path)
    end
  end

  context "box" do
    setup do
      Tenderloin::Commands.stubs(:box_foo)
      Tenderloin::Commands.stubs(:box_add)
      Tenderloin::Commands.stubs(:box_remove)
    end

    should "load the environment" do
      Tenderloin::Env.expects(:load!).once
      Tenderloin::Commands.box(["add"])
    end

    should "error and exit if the first argument is not 'add' or 'remove'" do
      Tenderloin::Commands.expects(:error_and_exit).once
      Tenderloin::Commands.box(["foo"])
    end

    should "not error and exit if the first argument is 'add' or 'remove'" do
      commands = ["add", "remove"]

      commands.each do |command|
        Tenderloin::Commands.expects(:error_and_exit).never
        Tenderloin::Commands.expects("box_#{command}".to_sym).once
        Tenderloin::Commands.box([command])
      end
    end

    should "forward any additional arguments" do
      Tenderloin::Commands.expects(:box_add).with(1,2,3).once
      Tenderloin::Commands.box(["add",1,2,3])
    end
  end

  context "box list" do
    setup do
      @boxes = ["foo", "bar"]

      Tenderloin::Box.stubs(:all).returns(@boxes)
      Tenderloin::Commands.stubs(:puts)
    end

    should "call all on box and sort the results" do
      @all = mock("all")
      @all.expects(:sort).returns(@boxes)
      Tenderloin::Box.expects(:all).returns(@all)
      Tenderloin::Commands.box_list
    end
  end

  context "box add" do
    setup do
      @name = "foo"
      @path = "bar"
    end

    should "execute the add action with the name and path" do
      Tenderloin::Box.expects(:add).with(@name, @path).once
      Tenderloin::Commands.box_add(@name, @path)
    end
  end

  context "box remove" do
    setup do
      @name = "foo"
    end

    should "error and exit if the box doesn't exist" do
      Tenderloin::Box.expects(:find).returns(nil)
      Tenderloin::Commands.expects(:error_and_exit).once
      Tenderloin::Commands.box_remove(@name)
    end

    should "call destroy on the box if it exists" do
      @box = mock("box")
      Tenderloin::Box.expects(:find).with(@name).returns(@box)
      @box.expects(:destroy).once
      Tenderloin::Commands.box_remove(@name)
    end
  end
end
