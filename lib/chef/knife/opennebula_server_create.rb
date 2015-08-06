#
# Author:: Matt Ray (<matt@getchef.com>)
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'chef/json_compat'
require 'chef/knife/opennebula_base'

class Chef
  class Knife
     class OpennebulaServerCreate < Knife

      deps do
        require 'highline'
        require 'chef/knife/bootstrap'
	Chef::Knife::Bootstrap.load_deps
      end
      include Knife::OpennebulaBase
  
      banner "knife opennebula server create OPTIONS"

      option :opennebula_template,
        :short => "-t TEMPLATE_NAME",
        :long => "--template-name TEMPLATE_NAME",
        :description => "name for the OpenNebula VM TEMPLATE",
        :required => true,
        :proc => Proc.new { |template| Chef::Config[:knife][:opennebula_template] = template}

      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server with knife bootstrap, default true",
        :boolean => true,
        :default => true

#It assumes that chef-client already installed in the server (ie) Image has installed with chef-client
#Chef-client install command
=begin
      option :bootstrap_install_command,
        :long => "--bootstrap_install_command",
        :description => "Bootstrap the server with the given chef-client install command",
        :default => "pwd"
=end

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The authorized user to ssh into the instance, default is 'root'",
        :default => "root"


      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port, default is 22",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :cpu,
        :long => "--cpu NO_OF_CORES",
        :description => "Number of cores(cpu) required for the VM, default is 1",
        :default => "1",
        :proc => Proc.new { |key| Chef::Config[:knife][:cpu] = key }

      option :vcpu,
        :long => "--vcpu No of vcpus",
        :description => "Number of virtual cpu required for the VM, default is 1",
        :default => "1",
        :proc => Proc.new { |key| Chef::Config[:knife][:vcpu] = key }

      option :memory,
        :short => "-R RAM",
        :long => "--ram RAM",
        :description => "Amout of ram required for the VM (in MB)",
        :default => "1024",
        :proc => Proc.new { |key| Chef::Config[:knife][:ram] = key }

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name for chef node and your vm",
        :required => true,
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of bootstrap template to use, default false",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }


      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!
	validate_flavor!

	newvm = connection.servers.new

newvm.flavor = connection.flavors.get(flavor.id)

# set the name of the vm
newvm.name = locate_config_value(:chef_node_name)

newvm.flavor.vcpu = locate_config_value(:vcpu)
newvm.flavor.memory = locate_config_value(:memory)
newvm.flavor.cpu = locate_config_value(:cpu)

vm = newvm.save
	
ser = server(vm.id)
        puts ui.color("\nServer:", :green)
        msg_pair("VM Name", ser.name)
        msg_pair("VM ID", ser.id)
        msg_pair("IP", ser.ip)
        msg_pair("CPU", locate_config_value(:cpu))
        msg_pair("VCPU", locate_config_value(:vcpu))
        msg_pair("RAM", locate_config_value(:ram))
        msg_pair("IP", ser.ip)
	msg_pair("Template", flavor.name)

        print "\n#{ui.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        ser.wait_for { print "."; ready? }

        puts("\n")
        # hack to ensure the nodes have had time to spin up
        print(".")
        sleep 30
        print(".")

        print(".") until tcp_test_ssh(ser.ip) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

#Bootstrap VM
        bootstrap(ser.ip)

        puts ui.color("Server:", :green)
        msg_pair("Name", ser.name)
        msg_pair("IP", ser.ip)
        msg_pair("CPU", locate_config_value(:cpu))
        msg_pair("VCPU", locate_config_value(:vcpu))
        msg_pair("RAM", locate_config_value(:ram))
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", config[:run_list].join(', '))
        msg_pair("JSON Attributes",config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
      end


      def bootstrap(ip)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = ip
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name)
        bootstrap.config[:bootstrap_install_command] = locate_config_value(:bootstrap_install_command)
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.run
      end

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def flavor
        @flavor ||= connection.flavors.get_by_name(locate_config_value(:opennebula_template))
	@flavor[0]
      end

      def server(id)
        @server ||= connection.servers.get(id)
      end

      def validate_flavor!
        if flavor.nil?
          ui.error("You have not provided a valid Template NAme. Please note the options for this value are -t or --template-name.")
          exit 1
        end
      end


    end
  end
end
