module Tenderloin
  module Actions
    module VM
      class Import < Base
        def execute!
          @runner.invoke_around_callback(:import) do
            Busy.busy do
              logger.info "Importing base VM (#{Tenderloin::Env.box.ovf_file})..."
              # Use the first argument passed to the action
              @runner.vm = VirtualBox::VM.import(Tenderloin::Env.box.ovf_file)
            end
          end
        end
      end
    end
  end
end
