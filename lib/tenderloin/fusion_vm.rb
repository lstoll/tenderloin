module Tenderloin
  class FusionVM
    VMRUN = "/Applications/VMware\\ Fusion.app/Contents/Library/vmrun"

    def initialize(vmx)
      @vmx = vmx
    end

    def start_fusion
      # Ensure fusion is running.
      `if [[ -z $(pgrep 'VMware Fusion') ]]; then open /Applications/VMware\\ Fusion.app ; sleep 5 ; fi`
    end

    def running?()
      `#{VMRUN} list | grep "#{@vmx}"`
      $? == 0 ? true : false
    end

    def start(opts = {})
      gui_opt = opts[:headless] == true ? "nogui" : "gui"
      res = `#{VMRUN} start #{@vmx} #{gui_opt}`
      unless $? == 0
        raise "Error starting VM: " + res
      end
    end

    def stop(opts = {})
      hard_opt = opts[:force] == true ? "hard" : "soft"
      res = `#{VMRUN} stop #{@vmx} #{hard_opt}`
      unless $? == 0
        raise "Error stopping VM: " + res
      end
    end

    def delete()
      res = `#{VMRUN} deleteVM #{@vmx}`
      unless $? == 0
        raise "Error deleting VM: " + res
      end
    end

    def self.get_guest_var(var)
      `#{VMRUN} readVariable #{@vmx} guestVar ip`
    end

    def ip
      @ip ||= get_guest_var('ip').strip
    end
  end
end
