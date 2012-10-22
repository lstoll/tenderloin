module Tenderloin
  def self.config
    Config.config
  end

  class Config
    @config = nil
    @config_runners = []

    class << self
      def reset!
        @config = nil
        config_runners.clear
      end

      def config
        @config ||= Config::Top.new
      end

      def config_runners
        @config_runners ||= []
      end

      def run(&block)
        config_runners << block
      end

      def execute!
        config_runners.each do |block|
          block.call(config)
        end

        config.loaded!
      end
    end
  end

  class Config
    class Base
      def [](key)
        send(key)
      end

      def to_json
        instance_variables_hash.to_json
      end

      def instance_variables_hash
        instance_variables.inject({}) do |acc, iv|
          acc[iv.to_s[1..-1].to_sym] = instance_variable_get(iv)
          acc
        end
      end
    end

    class SSHConfig < Base
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :key
      def keys=(keys)
        @keys=keys
      end
      def keys
        @keys || (key ? [key] : nil)
      end
      attr_accessor :port
    end

    class VMConfig < Base
      attr_accessor :box
      attr_accessor :box_url
      attr_accessor :box_vmx
      attr_accessor :project_directory
      attr_accessor :hd_location


      def initialize
      end

      def hd_location=(val)
        raise Exception.new "disk_storage must be set to a directory" unless File.directory?(val)
        @hd_location=val
      end

      def base
        File.expand_path(@base)
      end
    end

    class PackageConfig < Base
      attr_accessor :name
      attr_accessor :extension
    end

    class TenderloinConfig < Base
      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_accessor :home

      def home
        File.expand_path(@home)
      end
    end

    class ProvisioningConfig < Base
      attr_accessor :script
      attr_accessor :command
      attr_accessor :rsync
      def enabled
        script || command || !rsync.empty?
      end
    end

    class SharedFoldersConfig < Base
      attr_accessor :enabled
      attr_accessor :folders
    end

    class Top < Base
      attr_reader :package
      attr_reader :ssh
      attr_reader :vm
      attr_reader :tenderloin
      attr_reader :provisioning
      attr_reader :shared_folders

      def initialize
        @ssh = SSHConfig.new
        @vm = VMConfig.new
        @tenderloin = TenderloinConfig.new
        @package = PackageConfig.new
        @provisioning = ProvisioningConfig.new
        @shared_folders = SharedFoldersConfig.new

        @loaded = false
      end

      def loaded?
        @loaded
      end

      def loaded!
        @loaded = true
      end

      def to_hash
        hsh = Tenderloin.config.instance_variables_hash
        hsh.delete(:tenderloin)
        hsh = hsh.inject({}) do |h, (k, iv)|
          if iv.class.to_s =~ /Tenderloin::Config/
            h[k] = iv.instance_variables_hash
          else
            h[k] = iv
          end
          h
        end
        hsh
      end
    end
  end
end
