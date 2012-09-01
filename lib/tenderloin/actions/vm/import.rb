require 'fileutils'

module Tenderloin
  module Actions
    module VM
      class Import < Base
        def execute!
          @runner.invoke_around_callback(:import) do
            Busy.busy do
              logger.info "Importing base VM (#{Tenderloin::Env.box.vmx_file})..."
              # Use the first argument passed to the action
              # @runner.vm = VirtualBox::VM.import(Tenderloin::Env.box.ovf_file)
              @runner.vm_id = (0...15).map{ ('a'..'z').to_a[rand(26)] }.join
              vmdir = File.join(Tenderloin::Env.vms_path, @runner.vm_id)

              FileUtils.mkdir_p(vmdir) unless Dir.exists?(vmdir)

              # Copy the VMX over
              FileUtils.cp(Tenderloin::Env.box.vmx_file, File.join(vmdir, @runner.vm_id + ".vmx"))

              # Copy all VMDK's over
              Dir.glob(File.join(File.dirname(Tenderloin::Env.box.vmx_file), "*.vmdk")) do |f|
                FileUtils.cp File.expand_path(f), vmdir
              end

            end
          end
        end
      end
    end
  end
end
