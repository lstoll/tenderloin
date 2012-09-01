require 'fileutils'

module Tenderloin
  module Actions
    module VM
      class Destroy < Base
        def execute!
          @runner.execute!(Halt) if @runner.running?
          @runner.invoke_around_callback(:destroy) do
            logger.info "Destroying VM and associated drives..."
            @runner.fusion_vm.delete
            FileUtils.rm_rf(File.dirname(@runner.vmx_path))
          end
        end
      end
    end
  end
end
