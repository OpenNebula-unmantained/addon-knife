# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chef/opennebula/version"

Gem::Specification.new do |s|
  s.name        = "knife-opennebula"
  s.version     = Chef::Opennebula::VERSION
  s.authors     = ["Kishorekumar Neelamegam, Thomas Alrin"]
  s.email       = ["nkishore@megam.co.in","alrin@megam.co.in"]
  s.homepage    = "http://github.com/opennebula/addons-knife"
  s.license = "Apache V2"
  s.extra_rdoc_files = ["README.md" ]
  s.summary     = %q{Knife plugin to manage OpenNebula VMs}
  s.description = %q{Knife plugin to manage OpenNebula VMs}
  s.files         = ["Gemfile","README.md", "lib/chef/opennebula/version.rb","lib/chef/knife/opennebula_base.rb", "lib/chef/knife/opennebula_template_list.rb", "lib/chef/knife/opennebula_server_create.rb", "lib/chef/knife/opennebula_server_list.rb", "lib/chef/knife/opennebula_server_delete.rb" ]
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'opennebula'
  s.add_runtime_dependency 'chef'
  s.add_runtime_dependency 'highline'
end
