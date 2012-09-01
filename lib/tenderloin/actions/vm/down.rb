module Tenderloin
  module Actions
    module VM
      class Down < Base
        def prepare
          @runner.add_action(Halt) if @runner.running?
          @runner.add_action(Destroy)
        end
      end
    end
  end
end
