libdir = File.dirname(__FILE__)
$:.unshift(libdir)
PROJECT_ROOT = File.join(libdir, '..') unless defined?(PROJECT_ROOT)

# The libs which must be loaded prior to the rest
%w{tempfile open-uri json pathname logger uri net/http net/ssh archive/tar/minitar
  net/scp fileutils tenderloin/util tenderloin/actions/base tenderloin/downloaders/base tenderloin/actions/runner}.each do |f|
  require f
end

# Glob require the rest
Dir[File.join(PROJECT_ROOT, "lib", "tenderloin", "**", "*.rb")].each do |f|
  require f
end
