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
#Validate opennebula credentials
        validate!
#Get the template details
        temp = template("#{locate_config_value(:opennebula_template)}")
        unless "#{temp.class}" == "OpenNebula::Template"
          ui.error("Template Not found #{temp.class}")
          exit 1
        end
        puts ui.color("Instantiating Template......", :green)
#Instantiating a template
        vm_id = temp.instantiate(name = "#{locate_config_value(:chef_node_name)}", hold = false, template = "")
#Opennebula error message
	if OpenNebula.is_error?(vm_id)
	  ui.error("Some problem in instantiating template")
	  ui.error("#{vm_id.message}")
          exit -1
        end
        unless "#{vm_id.class}" == "Fixnum"
          ui.error("Some problem in instantiating template")
          exit 1
        end
        puts ui.color("Template Instantiated, and a VM created with id #{vm_id}", :green)
        puts ui.color("Fetching ip address of the VM ", :magenta)
#Get the VM details
        vir_mac = virtual_machine("#{vm_id}")
        unless "#{vir_mac.class}" == "OpenNebula::VirtualMachine"
          ui.error("Some problem in Getting Virtual Machine")
          exit 1
        end
        @vm_hash = vir_mac.to_hash
#VM can have more ip addresses. Priority to get vm ip is AWS_IP_ADDRESS, MEGAM_IP_ADDRESS and PRIVATE_IP_ADDRESS.
	if @vm_hash['VM']['TEMPLATE'].has_key?('AWS_IP_ADDRESS')
		@ip_add = @vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS']
	else
		@ip_add = @vm_hash['VM']['USER_TEMPLATE']['MEGAM_IP_ADDRESS']
	end
        puts ui.color("\nServer:", :green)
        msg_pair("Name", @vm_hash['VM']['name'])
        msg_pair("IP", @ip_add)
#Bootstrap VM
        bootstrap()

        puts ui.color("Server:", :green)
        msg_pair("Name", @vm_hash['VM']['name'])
        msg_pair("IP", @ip_add)
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
#Sleep untill get the VM's Ip address from either vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS'] or vm_hash['VM']['USER_TEMPLATE']['MEGAM_IP_ADDRESS'].
#vm_hash['VM']['USER_TEMPLATE']['MEGAM_IP_ADDRESS'] can be set by onegate. In our case, we get that ip from vpn.
            if v_hash['VM']['TEMPLATE'].has_key?('AWS_IP_ADDRESS') || v_hash['VM']['USER_TEMPLATE'].has_key?('MEGAM_IP_ADDRESS')
              @re_obj = vm
            else
              sleep 1
              print "."
              virtual_machine("#{vm.id}")
            end
          end
        end
        @re_obj
      end

      def template(name)
#Searching user's vm template
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
          end
        end
      end

      def bootstrap
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = @ip_add
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || @vm_hash['VM']['name']
        bootstrap.config[:use_sudo] = true unless bootstrap.config[:ssh_user] == 'root'
        bootstrap.run
      end

    end
  end
end
