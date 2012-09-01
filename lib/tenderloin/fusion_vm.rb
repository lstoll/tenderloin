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
      start_fusion
      gui_opt = opts[:headless] == true ? "nogui" : "gui"
      res = `#{VMRUN} start #{@vmx} #{gui_opt}`
      unless $? == 0
        raise "Error starting VM: " + res
      end
    end

    def self.get_guest_var(var)
      `#{VMRUN} readVariable #{@vmx} guestVar ip`
    end

    def ip
      get_guest_var('ip')
    end
  end
end
