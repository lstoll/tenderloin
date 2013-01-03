module Tenderloin
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'tenderloin-ssh-expect.sh')

    class << self
      def connect(ip, command = nil)
        if command
          remote_exec(ip, command)
        else
          ssh_connect(ip)
        end
      end

      def remote_exec(ip, command)
        execute(ip) do |ssh|
          ssh.open_channel do |channel|
            channel.exec command do |ch, success|
              raise "could not execute remote command: #{command}" unless success

              ch.on_data do |c, data|
                STDOUT.print data
              end

              ch.on_extended_data do |c, type, data|
                STDERR.print data
              end
            end
          end
        end
      end

      def ssh_connect(ip)
        if options.keys
          Kernel.exec "#{cmd_ssh_opts} #{options.username}@#{ip}"
        else
          Kernel.exec cmd_ssh_opts(ip).strip
        end
      end

      def execute(ip)
        Net::SSH.start(ip, Tenderloin.config[:ssh][:username], net_ssh_opts) do |ssh|
          yield ssh
        end
      end

      def upload!(ip, from, to)
        execute(ip) do |ssh|
          scp = Net::SCP.new(ssh)
          scp.upload!(from, to)
        end
      end

      def rsync(ip,src,dst)
        cmd = "rsync -avz --delete -e \"#{cmd_ssh_opts}\" #{src} #{options.username}@#{ip}:#{dst}"
        `#{cmd}`
      end

      def up?(ip)
        check_thread = Thread.new do
          begin
            Thread.current[:result] = false
            Net::SSH.start(ip, Tenderloin.config.ssh.username, net_ssh_opts) do |ssh|
              Thread.current[:result] = true
            end
          rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
            # False, its defaulted above
          end
        end

        check_thread.join(Tenderloin.config.ssh.timeout)
        return check_thread[:result]
      end

      def options
        Tenderloin.config.ssh
      end

      def cmd_ssh_opts(ip=nil)
        if options.keys
          keyopts = options.keys.map {|k| "-i #{File.expand_path(k)}"}.join(' ')
          "ssh #{keyopts} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p #{options.port}"
        else
          "#{SCRIPT} #{options.username} #{options.password} #{options.host || ip} #{options.port}".strip
        end
      end

      def net_ssh_opts
        opts = {}
        opts[:port] = Tenderloin.config.ssh.port
        opts[:password] = Tenderloin.config.ssh.password
        opts[:timeout] = Tenderloin.config.ssh.timeout
        opts[:keys] = Tenderloin.config[:ssh][:keys] if Tenderloin.config[:ssh][:keys]
        opts
      end
    end
  end
end
