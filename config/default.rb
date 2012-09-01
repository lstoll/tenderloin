Tenderloin::Config.run do |config|
  # default config goes here
  config.tenderloin.log_output = STDOUT
  config.tenderloin.dotfile_name = ".tenderloin"
  config.tenderloin.home = "~/.tenderloin"

  config.ssh.username = "tenderloin"
  config.ssh.password = "tenderloin"
  # config.ssh.host = "localhost"
  config.ssh.max_tries = 10
  config.ssh.timeout = 10

  config.vm.box_vmx = "box.vmx"
  config.vm.project_directory = "/tenderloin"

  config.package.name = 'tenderloin'
  config.package.extension = '.box'

  config.chef.enabled = false
  config.chef.cookbooks_path = "cookbooks"
  config.chef.provisioning_path = "/tmp/tenderloin-chef"
  config.chef.json = {
    :instance_role => "tenderloin",
    :recipes => ["tenderloin_main"]
  }
end
