module Tenderloin
  class FusionVM
    VMRUN = "/Applications/VMware\\ Fusion.app/Contents/Library/vmrun"

    def initialize(vmx)
      @vmx = vmx
    end

    def run(cmd, opts='')
      runcmd = "#{VMRUN} #{cmd} #{@vmx} #{opts}"
      retrycount = 0
      while true
        res = `#{runcmd}`
        if $? == 0
          return res
        elsif res =~ /The virtual machine is not powered on/
          return
        else
          if res =~ /VMware Tools are not running/
            sleep 1; next unless retrycount > 10
          end
          raise "Error running vmrun command:\n#{runcmd}\nResponse: " + res
        end
      end
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
      run('start', gui_opt)
    end

    def stop(opts = {})
      hard_opt = opts[:force] == true ? "hard" : "soft"
      run 'stop', hard_opt
    end

    def delete()
      run 'deleteVM'
    end

    def get_guest_var(var)
      run 'readVariable', 'guestVar ' + var
    end

    def ip
      ip = get_guest_var('ip')
      if ip && ip.strip =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
        ip = ip.strip
      else
        mac_address = VMXFile.load(@vmx)["ethernet0.generatedAddress"]
        ip = dhcp_leases[mac_address]
      end
      ip
    end

    def enable_shared_folders
      run 'enableSharedFolders'
    end

    def share_folder(name, hostpath)
      # Try and clean up first, to handle path changes.
      begin
        run 'removeSharedFolder', "#{name}"
      rescue
      end
      run 'addSharedFolder', "#{name} #{hostpath}"
    end

    def dhcp_leases
      mac_ip = {}
      curLeaseIp = nil
      Dir['/var/db/vmware/vmnet-dhcpd*.leases'].each do |f|
        File.open(f).each do |line|
          case line
          when /lease (.*) \{/
            curLeaseIp = $1
          when /hardware ethernet (.*);/
            mac_ip[$1] = curLeaseIp
          end
        end
      end
      mac_ip
    end

    def to_hash
      {:ip => ip, :running => running?}
    end
  end
end
