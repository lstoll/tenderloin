module Tenderloin
  module Actions
    module VM
      class Up < Base
        def prepare
          # If the dotfile is not a file, raise error
          if File.exist?(Env.dotfile_path) && !File.file?(Env.dotfile_path)
            raise ActionException.new(<<-msg)
The dotfile which Tenderloin uses to store the UUID of the project's
virtual machine already exists and is not a file! The dotfile is
currently configured to be `#{Env.dotfile_path}`

To change this value, please see `config.tenderloin.dotfile_name`
msg
          end

          # Up is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          Tenderloin::Box.add(Tenderloin.config.vm.box, Tenderloin.config.vm.box_url) unless Tenderloin::Env.box
          steps = [Import, SharedFolders, Boot]
          steps << Provision if provision_enabled?
          steps.insert(0, MoveHardDrive) if Tenderloin.config.vm.hd_location

          steps.each do |action_klass|
            @runner.add_action(action_klass)
          end
        end

        def after_import
          persist
          setup_uuid_mac
        end

        def persist
          logger.info "Persisting the VM UUID (#{@runner.vm_id})..."
          Env.persist_vm(@runner.vm_id)
        end

        def setup_uuid_mac
          logger.info "Resetting VMX UUID, MAC and Display Name..."

          VMXFile.with_vmx_data(@runner.vmx_path) do |data|
            data.delete "ethernet0.addressType"
            data.delete "uuid.location"
            data.delete "uuid.bios"
            data.delete "ethernet0.generatedAddress"
            data.delete "ethernet1.generatedAddress"
            data.delete "ethernet0.generatedAddressOffset"
            data.delete "ethernet1.generatedAddressOffset"
            data.delete 'displayname'
            data['displayName'] = "tenderloin-" + @runner.vm_id
          end
        end

        def provision_enabled?
          Tenderloin.config.provisioning.enabled && !run_args.include?(:no_provision)
        end
      end
    end
  end
end
