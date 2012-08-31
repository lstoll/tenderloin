module Tenderloin
  module Actions
    module VM
      class Provision < Base
        def execute!
          chown_provisioning_folder
          setup_json
          setup_solo_config
          run_chef_solo
        end

        def chown_provisioning_folder
          logger.info "Setting permissions on provisioning folder..."
          SSH.execute do |ssh|
            ssh.exec!("sudo chown #{Tenderloin.config.ssh.username} #{Tenderloin.config.chef.provisioning_path}")
          end
        end

        def setup_json
          logger.info "Generating JSON and uploading..."

          # Set up initial configuration
          data = {
            :config => Tenderloin.config,
            :directory => Tenderloin.config.vm.project_directory,
          }

          # And wrap it under the "tenderloin" namespace
          data = { :tenderloin => data }

          # Merge with the "extra data" which isn't put under the
          # tenderloin namespace by default
          data.merge!(Tenderloin.config.chef.json)

          json = data.to_json

          SSH.upload!(StringIO.new(json), File.join(Tenderloin.config.chef.provisioning_path, "dna.json"))
        end

        def setup_solo_config
          solo_file = <<-solo
file_cache_path "#{Tenderloin.config.chef.provisioning_path}"
cookbook_path "#{cookbooks_path}"
solo

          logger.info "Uploading chef-solo configuration script..."
          SSH.upload!(StringIO.new(solo_file), File.join(Tenderloin.config.chef.provisioning_path, "solo.rb"))
        end

        def run_chef_solo
          logger.info "Running chef recipes..."
          SSH.execute do |ssh|
            ssh.exec!("cd #{Tenderloin.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json") do |channel, data, stream|
              # TODO: Very verbose. It would be easier to save the data and only show it during
              # an error, or when verbosity level is set high
              logger.info("#{stream}: #{data}")
            end
          end
        end

        def cookbooks_path
          File.join(Tenderloin.config.chef.provisioning_path, "cookbooks")
        end

        def collect_shared_folders
          ["tenderloin-provisioning", File.expand_path(Tenderloin.config.chef.cookbooks_path, Env.root_path), cookbooks_path]
        end
      end
    end
  end
end
