module Tenderloin
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'tenderloin-ssh-expect.sh')

    class << self
      def connect(opts={})
        options = {}
        [:host, :password, :username, :key].each do |param|
          options[param] = opts[param] || Tenderloin.config.ssh.send(param)
        end

        if options[:key]
          Kernel.exec "ssh -i #{options[:key]} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p #{port(options)} #{options[:username]}@#{options[:host]}"
        else
          Kernel.exec "#{SCRIPT} #{options[:username]} #{options[:password]} #{options[:host]} #{port(options)}".strip
        end
      end

      def execute(ip)
        Net::SSH.start(ip, Tenderloin.config[:ssh][:username], ssh_opts) do |ssh|
          yield ssh
        end
      end

      def upload!(ip, from, to)
        execute(ip) do |ssh|
          scp = Net::SCP.new(ssh)
          scp.upload!(from, to)
        end
      end

      def up?(ip)
        check_thread = Thread.new do
          begin
            Thread.current[:result] = false
            Net::SSH.start(ip, Tenderloin.config.ssh.username, ssh_opts) do |ssh|
              Thread.current[:result] = true
            end
          rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
            # False, its defaulted above
          end
        end

        check_thread.join(Tenderloin.config.ssh.timeout)
        return check_thread[:result]
      end

      def port(opts={})
        opts[:port] || 22
      end

      def ssh_opts
        opts = {}
        opts[:port] = port
        opts[:password] = Tenderloin.config.ssh.password
        opts[:timeout] = Tenderloin.config.ssh.timeout
        opts[:keys] = [Tenderloin.config[:ssh][:key]] if Tenderloin.config[:ssh][:key]
        opts
      end
    end
  end
end
