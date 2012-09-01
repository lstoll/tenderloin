module Tenderloin
  class VMrun
    VMRUN = "/Applications/VMware\\ Fusion.app/Contents/Library/vmrun"

    def self.start_fusion
      # Ensure fusion is running.
      `if [[ -z $(pgrep 'VMware Fusion') ]]; then open /Applications/VMware\\ Fusion.app ; sleep 2 ; fi`
    end

    def self.running(vmx)
      `#{VMRUN} list | grep "#{vmx}"`
      $? == 0 ? true : false
    end

    def self.start(vmx, opts = {})
      start_fusion
      gui_opt = opts[:headless] == true ? "nogui" : "gui"
      res = `#{VMRUN} start #{vmx} #{gui_opt}`
      unless $? == 0
        raise "Error starting VM: " + res
      end
    end
  end
end
