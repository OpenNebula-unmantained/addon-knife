require 'chef/knife'
require 'chef/json_compat'
require 'chef/knife/opennebula_base'

#require_relative 'opennebula_base'
class Chef
  class Knife
    class OpennebulaServerCreate < Knife

      deps do
        require 'highline'
        require 'chef/knife/bootstrap'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife.load_deps
      end
      include Knife::OpennebulaBase

      banner "knife opennebula server create OPTIONS"

      option :vm_name,
        :short => "-n SERVER_NAME",
        :long => "--name SERVER_NAME",
        :description => "name for the newly created Server"
      #:required => true

      option :opennebula_template,
        :short => "-t TEMPLATE_NAME",
        :long => "--template-name TEMPLATE_NAME",
        :description => "name for the VM TEMPLATE",
        :required => true,
        :proc => Proc.new { |template| Chef::Config[:knife][:opennebula_template] = template}

      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server with knife bootstrap",
        :boolean => true,
        :default => true

      option :opennebula_flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "the amount of vCores and RAM that your server will get",
        #:required => true,
        :proc => Proc.new { |flavor| Chef::Config[:knife][:opennebula_flavor] = flavor }

      option :opennebula_storage,
        :long => "--storage SIZE",
        :description => "Specify the size (in GB) of the system drive. Valid size is 10-250",
        :default => '10',
        :proc => Proc.new { |size| Chef::Config[:knife][:opennebula_storage] = size }

      option :opennebula_ssd,
        :long => "--ssd 1",
        :description => "If this parameter is set to 1, the system drive will be located on a SSD drive",
        :proc => Proc.new { |set| Chef::Config[:knife][:opennebula_ssd] = set }

      option :opennebula_image,
        :short => "-I IMAGE_ID",
        :long => "--image IMAGE_ID",
        :description => "This image_id will define operating system and pre-installed software",
        #:required => true,
        :proc => Proc.new { |i| Chef::Config[:knife][:opennebula_image] = i }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The user to create and add the provided public key to authorized_keys, default is 'root'",
        :default => "root"

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "The AWS SSH key id",
        :proc => Proc.new { |key| Chef::Config[:knife][:aws_ssh_key_id] = key }

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

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
        :description => "The Chef node name for your new node default is the name of the server.",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!
        temp = template("#{locate_config_value(:opennebula_template)}")
        unless "#{temp.class}" == "OpenNebula::Template"
          ui.error("Template Not found")
          exit 1
        end
        puts ui.color("Instantiating Template......", :green)
        vm_id = temp.instantiate(name = "#{locate_config_value(:vm_name)}", hold = false, template = "")
        unless "#{vm_id.class}" == "Fixnum"
          ui.error("Some problem in instantiating template")
          exit 1
        end
        puts ui.color("Template Instantiated, and a Virtual Machine created with id #{vm_id}", :green)
        puts ui.color("Fetching Virtual machine data from cloud", :magenta)
        vir_mac = virtual_machine("#{vm_id}")
        unless "#{vir_mac.class}" == "OpenNebula::VirtualMachine"
          ui.error("Some problem in Getting Virtual Machine")
          exit 1
        end
        @vm_hash = vir_mac.to_hash
        puts ui.color("\nServer:", :green)
        msg_pair("Name", @vm_hash['VM']['name'])
        msg_pair("IP", @vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS'])

        bootstrap()

        puts ui.color("Server:", :green)
        msg_pair("Name", @vm_hash['VM']['name'])
        msg_pair("IP", @vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS'])
      end

      def virtual_machine(id)
        vm_pool = VirtualMachinePool.new(client, -1)
        rc = vm_pool.info
        if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
        end
        vm_pool.each do |vm|
          if "#{vm.id}" == "#{id}"
            v_hash = vm.to_hash
            ## To do, this needs to fixed. Get help from Opennebula dev team.
            if v_hash['VM']['TEMPLATE'].has_key?('AWS_IP_ADDRESS')
              @re_obj = vm
            else
              sleep 1
              print "."
              virtual_machine("#{vm.id}")
            end
          else
            ui.error("Virtual Machine Not found")
            exit 1
          end
        end
        @re_obj
      end

      def template(name)
        puts ui.color("Locating Template......", :green)
        temp_pool = TemplatePool.new(client, -1)
        rc = temp_pool.info
        if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
        end
        temp_pool.each do |temp|
          if "#{temp.name}" == "#{name}"
            puts ui.color("Template Found.", :green)
          return temp
          else
            ui.error("Template Not found")
            exit 1
          end
        end
      end

      def bootstrap
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = @vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS']
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || @vm_hash['VM']['name']
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.run
      end

    end
  end
end
