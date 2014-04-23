require 'chef/knife'

class Chef
  class Knife
    module OpennebulaBase

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
