require 'chef/knife'
require 'chef/json_compat'
require 'chef/knife/opennebula_base'

#require_relative 'opennebula_base'
class Chef
  class Knife
    class OpennebulaTemplateList < Knife

      deps do
        require 'highline'
        Chef::Knife.load_deps
      end
      include Knife::OpennebulaBase

      banner "knife opennebula template list OPTIONS"

      option :opennebula_username,
        :short => "-A OPENNEBULA_USERNAME",
        :long => "--username OPENNEBULA_USERNAME",
        :description => "Opennebula user's name",
        :proc => Proc.new { |user| Chef::Config[:knife][:opennebula_username] = user }

      option :opennebula_passowrd,
        :short => "-K OPENNEBULA_PASSWORD",
        :long => "--password OPENNEBULA_PASSWORD",
        :description => "Opennebula user's password",
        :proc => Proc.new { |password| Chef::Config[:knife][:opennebula_password] = password }

      option :opennebula_endpoint,
        :short => "-e OPENNEBULA_ENDPOINT",
        :long => "--endpoint OPENNEBULA_ENDPOIN",
        :description => "Opennebula Endpoint",
        :proc => Proc.new { |endpoint| Chef::Config[:knife][:opennebula_endpoint] = endpoint }

      def h
        @highline ||= HighLine.new
      end

      def run
        validate!

        temp_pool = TemplatePool.new(client, -1)
        rc = temp_pool.info
        if OpenNebula.is_error?(rc)
          puts rc.message
          exit -1
        end

        temp_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('AMI', :bold),
          ui.color('INSTANCE_TYPE', :bold),
          ui.color('KEY_PAIR', :bold),
          ui.color('SECURITY_GROUP', :bold),
          ui.color('CPU', :bold),
          ui.color('MEMORY', :bold)]

        temp_pool.each do |temp|
          temp_hash = temp.to_hash
          temp_list << temp_hash['VMTEMPLATE']['ID']
          temp_list << temp_hash['VMTEMPLATE']['NAME']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['EC2']['AMI']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['EC2']['INSTANCETYPE']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['EC2']['KEYPAIR']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['EC2']['SECURITYGROUPS']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['CPU']
          temp_list << temp_hash['VMTEMPLATE']['TEMPLATE']['MEMORY']
        end

        puts ui.color("VM Templates Listed Successfully", :green)
        puts ui.list(temp_list, :uneven_columns_across, 8)
      end

    end
  end
end
