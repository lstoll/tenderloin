# Tenderloin

* Website: [http://tenderloinup.com](http://tenderloinup.com)
* IRC: `#tenderloin` on Freenode
* Mailng list: [Google Groups](http://groups.google.com/group/tenderloin-up)

Tenderloin is a tool for building and distributing virtualized development environments.

By providing automated creation and provisioning of virtual machines using [Sun’s VirtualBox](http://www.virtualbox.org),
Tenderloin provides the tools to create and configure lightweight, reproducible, and portable
virtual environments. For more information, see the part of the getting started guide
on ”[Why Tenderloin?](http://tenderloinup.com/docs/getting-started/index.html)”

## Quick Start

First, make sure your development machine has [VirtualBox](http://www.virtualbox.org)
installed. The setup from that point forward is very easy, since Tenderloin is simply
a rubygem.

    sudo gem install tenderloin

To build your first virtual environment:

    tenderloin init
    tenderloin box add base http://files.tenderloinup.com/base.box
    tenderloin up

## Getting Started Guide and Video

To learn how to build a fully functional rails development environment, view the
[getting started guide](http://tenderloinup.com/getting-started/index.html).

There is also a fairly short (12 minute) [getting started video](http://vimeo.com/9976342) which
explains how to build a fully functional LAMP development environment, which
covers a few parts of Tenderloin in more detail than the website guide.

## Installing the Gem from Git

If you want the bleeding edge version of Tenderloin, we try to keep master pretty stable
and you're welcome to give it a shot. The following is an example showing how to do this:

    rake build
    sudo rake install

## Contributing to Tenderloin

To hack on tenderloin, you'll need [bundler](http://github.com/carlhuda/bundler) which can
be installed with a simple `sudo gem install bundler`. Afterwords, do the following:

    bundle install
    rake

This will run the test suite, which should come back all green! Then you're good to go!
