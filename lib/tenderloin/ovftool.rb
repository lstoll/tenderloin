module Tenderloin
  class OVFTool
    TOOL = "/Applications/VMware\\ Fusion.app//Contents/Library/VMware\\ OVF\\ Tool/ovftool"

    def self.run(cmd, opts = '')
      res = `#{TOOL} #{opts} #{cmd}`
      if $? == 0
        return res
      else
        raise "Error running ovftool command #{cmd}: " + res
      end
    end

    def self.ovf2vmx(ovf, vmx, opts = {})
      cmd_opts = []
      cmd_opts << '--lax' if opts[:lax]
      run("#{cmd_opts.join(' ')} #{ovf} #{vmx}")
    end

  end
end
