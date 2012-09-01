module Tenderloin
  module Actions
    module VM
      class Halt < Base
        def execute!
          raise ActionException.new("VM is not running! Nothing to shut down!") unless @runner.running?

          logger.info "Forcing shutdown of VM..."
          @runner.fusion_vm.stop(:force => true)
        end
      end
    end
  end
end
