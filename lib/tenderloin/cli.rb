require 'thor'
require 'tenderloin'

module Tenderloin

  class CLI < Thor
    class_option :file, :aliases => :'-f', :default => "Tenderfile"

    no_tasks do
      def setup
        $ROOTFILE_NAME = options[:file].dup.freeze
      end
    end

    desc "up [--file <tenderfile> --no-provision]", "Boots the VM"
    method_option :provision, :default => true
    def up()
      setup

      if !options[:provision]
        Tenderloin::Commands.up(:no_provision)
      else
        Tenderloin::Commands.up
      end
    end

    desc "halt [--file <tenderfile>]", "Force shuts down the running VM"
    def halt()
      setup
      Tenderloin::Commands.halt
    end

    desc "destroy [--file <tenderfile>]", "Shuts down and deletes the VM"
    def destroy()
      setup
      Tenderloin::Commands.destroy
    end

    desc "box [--file <tenderfile>]", "Manages base boxes"
    # TODO - make the box command use real args/a subcommand
    def box(arg1=nil, arg2=nil, arg3=nil, arg4=nil)
      setup
      Tenderloin::Commands.box([arg1, arg2, arg3, arg4].compact)
    end

    desc "init [--file <tenderfile>]", "Creates a new Tenderfile"
    def init()
      setup
      Tenderloin::Commands.init
    end

    desc "reload [--file <tenderfile>]", "Reboots & re-provisions the VM"
    def reload()
      setup
      Tenderloin::Commands.reload
    end

    desc "provision [--file <tenderfile>]", "Runs the provisioning script"
    def provision()
      setup
      Tenderloin::Commands.provision
    end

    desc "ssh [--file <tenderfile> --command <ssh command>]", "SSH's in to the VM"
    method_option :command, :aliases => "-c"
    def ssh()
      setup
      Tenderloin::Commands.ssh(options[:command])
    end

    desc "ip [--file <tenderfile>]", "Shows the IP to access the VM"
    def ip()
      setup
      Tenderloin::Commands.show_ip
    end

    desc "jsondump [--file <tenderfile>]", "Dumps a JSON representation of the VM"
    def jsondump
      setup
      Tenderloin::Commands.json_dump
    end

  end
end
