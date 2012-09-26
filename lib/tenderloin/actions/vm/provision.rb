module Tenderloin
  module Actions
    module VM
      class Provision < Base
        def execute!
          run_rsync if Tenderloin.config.provisioning.rsync
          setup_script if Tenderloin.config.provisioning.script
          run_command if Tenderloin.config.provisioning.command
        end

        def run_rsync
          Tenderloin.config.provisioning.rsync.each do |rsync|
            logger.info "Running rsync for #{rsync.join(' -> ')}..."
            src, dst = *rsync
            SSH.execute(@runner.fusion_vm.ip) do |ssh|
              ssh.exec!("mkdir -p #{dst}")
            end
            logger.info SSH.rsync(@runner.fusion_vm.ip, File.expand_path(src), File.expand_path(dst))
          end
        end

        def setup_script
          logger.info "Uploading provisioning script..."

          SSH.upload!(@runner.fusion_vm.ip, StringIO.new(Tenderloin.config.provisioning.script), File.join('/tmp', "tenderloin_provision.sh"))

          Tenderloin.config.provisioning.command = "/tmp/tenderloin_provision.sh"
        end

        def run_command
          logger.info "Running Provisioning command..."
          cmd = ""
          cmd << "chmod +x /tmp/tenderloin_provision.sh && " if Tenderloin.config.provisioning.script
          cmd << Tenderloin.config.provisioning.command
          SSH.execute(@runner.fusion_vm.ip) do |ssh|
            ssh.exec!(cmd) do |channel, data, stream|
              # TODO: Very verbose. It would be easier to save the data and only show it during
              # an error, or when verbosity level is set high
              logger.info("#{stream}: #{data}")
            end
          end
        end

      end
    end
  end
end
