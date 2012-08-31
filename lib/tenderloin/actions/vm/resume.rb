module Tenderloin
  module Actions
    module VM
      class Resume < Base
        def execute!
          if !@runner.vm.saved?
            raise ActionException.new("The tenderloin virtual environment you are trying to resume is not in a suspended state.")
          end

          logger.info "Resuming suspended VM..."
          @runner.start
        end
      end
    end
  end
end
