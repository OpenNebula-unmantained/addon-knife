knife-opennebula
================

Knife plugin for Opennebula IaaS

Installation
------------
If you are not using bundler, you can install the gem manually. Be sure you are running Chef 0.10.10 or higher, as earlier versions do not support plugins.

    $ gem install chef

This plugin is distributed as a Ruby Gem. To install it, run:

    $ gem install knife-opennebula

Depending on your system's configuration, you may need to run this command with root privileges.

Subcommands
-----------
This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag


#### `knife opennebula template list`


#### `knife opennebula vm list`


#### `knife opennebula template instantiate`

eg:

    knife opennebula vm list -A OPENNEBULA_USERNAEM -K OPENNEBULA_USER_PASSWORD -e http://my-opennebula.com:2633/RPC2

    knife opennebula template list -A OPENNEBULA_USERNAEM -K OPENNEBULA_USER_PASSWORD -e http://my-opennebula.com:2633/RPC2

    knife opennebula template instantiate -A OPENNEBULA_USERNAEM -K OPENNEBULA_USER_PASSWORD -e http://my-opennebula.com:2633/RPC2 -t MY_TEMPLATE_NAME -i IDENTITY_FILE -x USER -r 'role[test]' -N TEST1 -n TEST1
