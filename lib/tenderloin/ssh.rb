module Tenderloin
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'tenderloin-ssh-expect.sh')

    class << self
      def connect(opts={})
        options = {}
        [:host, :password, :username].each do |param|
          options[param] = opts[param] || Tenderloin.config.ssh.send(param)
        end

        Kernel.exec "#{SCRIPT} #{options[:username]} #{options[:password]} #{options[:host]} #{port(opts)}".strip
      end

      def execute(ip)
        Net::SSH.start(ip, Tenderloin.config[:ssh][:username], :port => port, :password => Tenderloin.config[:ssh][:password]) do |ssh|
          yield ssh
        end
      end

      def upload!(from, to)
        execute do |ssh|
          scp = Net::SCP.new(ssh)
          scp.upload!(from, to)
        end
      end

      def up?(ip)
        check_thread = Thread.new do
          begin
            Thread.current[:result] = false
            Net::SSH.start(ip, Tenderloin.config.ssh.username, :port => port, :password => Tenderloin.config.ssh.password, :timeout => Tenderloin.config.ssh.timeout) do |ssh|
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
    end
  end
end
