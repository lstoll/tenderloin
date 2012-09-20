# Tenderloin

Tenderloin is a tool for building and distributing virtualized development environments.

It is based on [Vagrant](http://vagrantup.com), specifically the 0.1.4 release. This was
the simplest, and provided a good starting point

It is designed to use VMWare Fusion as the underlying provider. It has only been tested with Version 5. In theory this should be adaptable easily to VMWare workstation on other platforms, by updating the path to vmrun/the DHCP config.

Features:

* Shared folders
* Provisioning via command or script
* Imports Vagrant boxes
* Sync data via rsync (Allows target VMs to not have tools)

## Quick Start

    gem install tenderloin

To build your first virtual environment:

    loin init
    # Warning! I'm 2gb's and un-optimized
    loin box add base http://s3.lstoll.net/tenderloin/precise64.box
    loin up

The file describing your VM is called 'Tenderfile', but you can optionally change this with
the -f flag, to allow multiple VM descriptions in the same place, e.g `loin up -f esxi.loin`

## Using Vagrant Boxes.

You can reference vagrant boxes directly, and the importer will convert them to native VMWare. The imported VM won't have additions installed, so you won't be able to use shared folders.

## Provisioning

Provisioning is either via a shell script, or by launching a command directly. Chef and Puppet provisioning isn't natively supported - if you wish to use these you will need to write your own launcher script.

You can also set up paths to rsync using the provisioner, these wil be synced with --delete before the proisioning script/command runs. This is useful for machines that don't have the additions installed, and avoids using shared folders

## Tenderfile

You can [view the template](templates/Tenderfile) to see all available options.

## Project status

This project is currently still in a pretty raw state. It is a quick hack to see how it would work, and to directly achieve a goal. The tests are broken, and the code might still be rough. I am currently using it on a daily basis though, so it's definitely usable.

## Building base boxes

Currently base boxes are built manually. The process:

* Create image in Fusion
* Set user and password to 'tenderloin'
* Set sudo to not prompt for password
* Install VMWare additions
* Ensure you have a single .vmdk disk. If not, convert with:

    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -r Virtual\ Disk.vmdk -t 0 precise64.vmdk

and then edit the vmx to point to this.

* Compress and shrink the disk

    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -d precise64.vmdk
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -k precise64.vmdk

* Create a Tenderfile. Example:

    Tenderloin::Config.run do |config|
        config.vm.box_vmx = "precise64.vmx"
    end

* Tar them up as a .box

    tar -cvf precise64.box precise64.vmx Tenderfile precise64.vmdk
