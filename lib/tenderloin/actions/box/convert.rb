module Tenderloin
  module Actions
    module Box
      # If the box is vagrant format, it converts it to something suitible for tenderloin
      class Convert < Base

        def execute!
          if !Dir[@runner.directory + '/Tenderfile'].empty?
            # We can do nothing - pretenderized
            logger.info "Tenderloin box provided"
          elsif !Dir[@runner.directory + '/Vagrantfile'].empty?
            # Need to import from Vagrant. Convert the ovf to vmx using OVFtool, then write a base tenderfile
            logger.info "Vagrant box provided, converting"
            convert_ovf
            write_tenderfile
            logger.info "Vagrant box converted. It has a basic Tenderfile, you may want to customize this if needed"
            logger.info "This file can be found in #{@runner.directory}"
          else
            raise "Invalid box - No Tenderfile or Vagrantfile"
          end
        end

        def convert_ovf
          ovf = File.join(@runner.directory, 'box.ovf')
          vmx = File.join(@runner.directory, 'vmwarebox.vmx')
          OVFTool.ovf2vmx(ovf, vmx, :lax => true)
          FileUtils.rm_rf(@runner.directory)
          FileUtils.mv(@runner.directory + ".vmwarevm", @runner.directory)
        end

        def write_tenderfile
          tenderfile = <<EOF
Tenderloin::Config.run do |config|
    config.vm.box_vmx = "vmwarebox.vmx"
end
EOF
          File.open(File.join(@runner.directory, 'Tenderfile'), 'w') {|f| f.write(tenderfile) }
        end
      end
    end
  end
end
