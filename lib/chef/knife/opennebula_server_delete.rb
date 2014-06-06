require 'chef/knife'
require 'chef/json_compat'
require 'chef/knife/opennebula_base'

#require_relative 'opennebula_base'
class Chef
  class Knife
    class OpennebulaServerDelete < Knife

      deps do
        require 'highline'
        Chef::Knife.load_deps
      end
      include Knife::OpennebulaBase

      banner "knife opennebula server delete VM_NAME (OPTIONS)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the opennebula vm itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."


      def h
        @highline ||= HighLine.new
      end

      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run
        validate!
        if @name_args.empty?
          ui.error("no vm name is specific")
          exit -1
        else
          @vm_name = @name_args[0]
        end
        vm_pool = VirtualMachinePool.new(client, -1)
        rc = vm_pool.info
        if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
        end

        vm_pool.each do |vm|
          if "#{vm.name}" == "#{@vm_name}"
            @vm_hash = vm.to_hash
            msg_pair("VM ID", @vm_hash['VM']['ID'])
            msg_pair("VM Name", @vm_hash['VM']['NAME'])
            msg_pair("Availability Zone", @vm_hash['VM']['TEMPLATE']['AWS_AVAILABILITY_ZONE'])
            msg_pair("Public IP Address", @vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS'])
            confirm("Do you really want to delete this server")
            vm.undeploy(hard = false)
            vm.delete(recreate = false)
            ui.warn("Deleted server #{@vm_hash['VM']['NAME']}")
            if config[:purge]
              if config[:chef_node_name]
                thing_to_delete = config[:chef_node_name]
                destroy_item(Chef::Node, thing_to_delete, "node")
                destroy_item(Chef::ApiClient, thing_to_delete, "client")
              else
                ui.error("Please Provide Chef NODE_NAME in -N")
              end
            else
              ui.warn("Corresponding node and client for the #{@vm_name} server were not deleted and remain registered with the Chef Server")
            end
          end
        end

      end

    end
  end
end
