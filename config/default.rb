Tenderloin::Config.run do |config|
  # default config goes here
  config.tenderloin.log_output = STDOUT
  config.tenderloin.dotfile_name = ".tenderloin"
  config.tenderloin.home = "~/.tenderloin"

  config.ssh.username = "tenderloin"
  config.ssh.password = "tenderloin"
  config.ssh.key = nil
  config.ssh.port = 22
  # config.ssh.host = "localhost"
  config.ssh.max_tries = 10
  config.ssh.timeout = 30

  config.vm.box_vmx = "box.vmx"
  config.vm.project_directory = "/tenderloin"

  config.package.name = 'tenderloin'
  config.package.extension = '.box'

  config.provisioning.script = nil
  config.provisioning.command = nil
  config.provisioning.rsync = []

  config.shared_folders.enabled = true
  config.shared_folders.folders = []
end
