# Base Boxes

## ESXi

Create machine, setup for DHCP

* username: root
* password: password
* IP: Assigned by DHCP, will display when booted
* Disk: 40GB (expanding)
* Storage: Local
* RAM: 2GB (Sufficient for multiple, smaller VMs or a larger VM.)
* Networking: Single IP, NAT

Boot machine. From console, customize system. In troubleshooting, enable SSH and Shell.
SSH in, run `esxcfg-advcfg -s 1 /Net/FollowHardwareMac`

Tenderfile:

    Tenderloin::Config.run do |config|
        config.vm.box_vmx = "esxi5.vmx"

        config.ssh.username = "root"
        config.ssh.password = "password"
    end
