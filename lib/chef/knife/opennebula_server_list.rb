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
    class OpennebulaServerList < Knife

      include Knife::OpennebulaBase

      banner "knife opennebula server list (options)"

      def run

        validate!

        server_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('IP', :bold),
          ui.color('Memory', :bold),
          ui.color('State', :bold)]

        connection.servers.all.each do |server|
          server_list << "#{server.id.to_s}"
          server_list << server.name
          server_list << server.ip
          server_list << "#{server.memory.to_s}"
          server_list << server.state
        end
        puts ui.list(server_list, :uneven_columns_across, 5)
      end
    end
  end
end
