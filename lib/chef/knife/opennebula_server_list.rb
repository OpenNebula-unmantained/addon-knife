require 'chef/knife'
require 'chef/json_compat'
require 'chef/knife/opennebula_base'

#require_relative 'opennebula_base'
class Chef
  class Knife
    class OpennebulaServerList < Knife

      deps do
        require 'highline'
        Chef::Knife.load_deps
      end
      include Knife::OpennebulaBase

      banner "knife opennebula server list OPTIONS"

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!

        vm_pool = VirtualMachinePool.new(client, -1)
        rc = vm_pool.info
        if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
        end

        vm_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('Memory', :bold),
          ui.color('Cpu', :bold),
          ui.color('AWS_ZONE', :bold),
          ui.color('INSTANCE_TYPE', :bold),
          ui.color('IP', :bold),
          ui.color('AWS_Key', :bold),
          ui.color('State', :bold)]
        vm_pool.each do |vm|
          vm_hash = vm.to_hash
          vm_list << vm_hash['VM']['ID']
          vm_list << vm_hash['VM']['NAME']
          vm_list << vm_hash['VM']['TEMPLATE']['MEMORY']
          vm_list << vm_hash['VM']['TEMPLATE']['CPU']
          vm_list << vm_hash['VM']['TEMPLATE']['AWS_AVAILABILITY_ZONE'] if vm_hash['VM']['TEMPLATE'].has_key?('AWS_AVAILABILITY_ZONE')
          vm_list << vm_hash['VM']['TEMPLATE']['AWS_INSTANCE_TYPE'] if vm_hash['VM']['TEMPLATE'].has_key?('AWS_INSTANCE_TYPE')
          vm_list << vm_hash['VM']['TEMPLATE']['AWS_IP_ADDRESS'] if vm_hash['VM']['TEMPLATE'].has_key?('AWS_IP_ADDRESS')
          vm_list << vm_hash['VM']['TEMPLATE']['AWS_KEY_NAME'] if vm_hash['VM']['TEMPLATE'].has_key?('AWS_KEY_NAME')
          vm_list <<  begin
            state = vm_hash['VM']['STATE']
            case state
            when '1'
              ui.color(state, :red)
            when '2'
              ui.color(state, :yellow)
            else
            ui.color(state, :green)
            end
          end

        end
        puts ui.color("Virtual Machines Listed Successfully", :green)
        puts ui.list(vm_list, :uneven_columns_across, 9)

      end

    end
  end
end
