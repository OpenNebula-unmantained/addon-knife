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
    class OpennebulaTemplateList < Knife

      include Knife::OpennebulaBase

      banner "knife opennebula template list (options)"

      def run

        validate!

        flavor_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('CPU', :bold),
          ui.color('MEMORY', :bold)]

        connection.flavors.all.each do |flavor|
          flavor_list << flavor.id
          flavor_list << flavor.name
          flavor_list << flavor.cpu.to_s
          flavor_list << "#{flavor.memory.to_s} MB"
        end
        puts ui.list(flavor_list, :uneven_columns_across, 4)
      end
    end
  end
end
