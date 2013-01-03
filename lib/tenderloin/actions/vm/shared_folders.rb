require 'timeout'

module Tenderloin
  module Actions
    module VM
      class SharedFolders < Base
        def shared_folders
          shared_folders = @runner.invoke_callback(:collect_shared_folders)

          shared_folders = shared_folders + Tenderloin.config.shared_folders.folders

          # Basic filtering of shared folders. Basically only verifies that
          # the result is an array of 3 elements. In the future this should
          # also verify that the host path exists, the name is valid,
          # and that the guest path is valid.
          shared_folders.collect do |folder|
            if folder.is_a?(Array) && folder.length == 3
              folder
            else
              nil
            end
          end#.compact
        end

        def before_boot

        end

        def after_boot
          if Tenderloin.config.shared_folders.enabled
            logger.info "Creating shared folders metadata..."

            # Enable Shared Folders. It fails if it's already enabled.
            # If it's a real error the command to add a shared folder will fail,
            # so we can ignore this one.
            @runner.fusion_vm.enable_shared_folders rescue nil

            shared_folders.each do |name, hostpath, guestpath|
              4.times do
                begin
                  Timeout::timeout(10) {
                    @runner.fusion_vm.share_folder(name, File.expand_path(hostpath))
                    break
                  }
                rescue Timeout::Error
                  logger.warn "Sharing folder #{name} timed out"
                end
              end
            end

            logger.info "Linking shared folders..."

            Tenderloin::SSH.execute(@runner.fusion_vm.ip) do |ssh|
              shared_folders.each do |name, hostpath, guestpath|
                logger.info "-- #{name}: #{guestpath}"
                ssh.exec!("sudo ln -s /mnt/hgfs/#{name} #{guestpath}")
                ssh.exec!("sudo chown #{Tenderloin.config.ssh.username} #{guestpath}")
              end
            end
          end
        end

      end
    end
  end
end
