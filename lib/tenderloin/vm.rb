module Tenderloin
  class VM < Actions::Runner
    include Tenderloin::Util

    attr_accessor :vm_id
    attr_accessor :from

    class << self
      # Finds a virtual machine by a given UUID and either returns
      # a Tenderloin::VM object or returns nil.
      def find(uuid)
        # TODO - just validate the existence - there's no 'loading' needed
        new(uuid) if File.exists? File.join(Tenderloin::Env.vms_path, uuid, uuid + ".vmx")
      end
    end

    def initialize(vm=nil)
      @vm_id = vm
    end

    def package(out_path, include_files=[])
      add_action(Actions::VM::Export)
      add_action(Actions::VM::Package, out_path, include_files)
      execute!
    end

    def vmx_path
      File.join(Tenderloin::Env.vms_path, @vm_id, @vm_id + ".vmx")
    end

    def fusion_vm
      @fusion_vm ||= FusionVM.new(vmx_path) if vmx_path
    end

    def start
      return if running?

      execute!(Actions::VM::Start)
    end

    def running?
      fusion_vm.running?
    end

    def destroy
      execute!(Actions::VM::Destroy)
    end

    def suspend
      execute!(Actions::VM::Suspend)
    end

    def resume
      execute!(Actions::VM::Resume)
    end

    def saved?
      @vm.saved?
    end

    def powered_off?; @vm.powered_off? end
  end
end
