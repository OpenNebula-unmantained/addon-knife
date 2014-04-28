require 'chef/knife'

class Chef
  class Knife
    module OpennebulaBase

    def self.included(includer)
        includer.class_eval do

         deps do
        require 'highline'
        require 'chef/json_compat'
        Chef::Knife.load_deps
      end

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
        end
      end


      require 'opennebula'

      include OpenNebula

      def validate!
        if (!opennebula_username)
          ui.error "You did not configure your opennebula_username"
          exit 1
        elsif (!opennebula_password)
          ui.error "You did not configure your opennebula_password"
          exit 1
        elsif (!opennebula_endpoint)
          ui.error "You did not configure your opennebula_endpoint"
          exit 1
        end
      end

      def client
        cli = Client.new("#{opennebula_username}:#{opennebula_password}", "#{opennebula_endpoint}")
        cli
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          ui.info "#{ui.color(label, color)}: #{value}"
        end
      end

      def opennebula_username
        locate_config_value(:opennebula_username) || ENV['OPENNEBULA_USERNAME']
      end

      def opennebula_password
        locate_config_value(:opennebula_password) || ENV['OPENNEBULA_PASSWORD']
      end

      def opennebula_endpoint
        locate_config_value(:opennebula_endpoint) || ENV['OPENNEBULA_ENDPOINT']
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

    end
  end
end
