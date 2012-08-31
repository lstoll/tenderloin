# Tenderloin

Tenderloin is a tool for building and distributing virtualized development environments.

It is based on [Vagrant](http://vagrantup.com), specifically the 0.1.4 release. This was
the simplest, and provided a good starting point

It is designed to use VMWare Fusion as the underlying provider. You will need Fusion 5.

## Quick Start

    gem install tenderloin

To build your first virtual environment:

    loin init
    loin box add base http://s3.lstoll.net/<todo>.box
    loin up

## Builsding base boxes

Currently base boxes are built manually. The process:

* Create image in Fusion
* Set user and password to 'tenderloin'
* Set sudo to not prompt for password
* Install VMWare additions
* Ensure you have a single .vmdk disk. If not, convert with:

    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -r Virtual\ Disk.vmdk -t 0 precise64.vmdk

* Compress and shrink the disk

    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -d precise64.vmdk
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -k precise64.vmdk

* Take the vmdk and a base Tenderfile, and tar them up as a .box

    tar -cvf precise64.box Tenderfile precise64.vmdk
