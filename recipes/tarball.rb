#
# Cookbook Name:: activemq
# Recipe:: tarball
#
# Copyright 2014, Virender Khatri
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

Chef::Application.fatal!("attribute node['activemq']['cluster_name'] not defined") unless node.activemq.cluster_name

# Setup activemq Service User
if node.activemq.setup_user
  include_recipe "activemq::user"
end

require "tmpdir"

# If running activemq, maintain Zookeeper in its own recipe
# Adding Zookeeper cookbook depending upon node.activemq.node_type
# include_recipe "zookeeper" if node.activemq.node_type == 'cloud_zk'
# Disabling Zookeeper Integration Cookbook for now

temp_d        = Dir.tmpdir
tarball_file  = File.join(temp_d, "apache-activemq-#{node.activemq.version}.tgz")
tarball_dir   = File.join(temp_d, "apache-activemq-#{node.activemq.version}")

# Stop activemq Service if running for Version Upgrade
service "activemq" do
  service_name  node.activemq.service_name
  action        :stop
  only_if       { File.exists? "/etc/init.d/#{node.activemq.service_name}" and not File.exists?(node.activemq.source_dir) }
end

# activemq Version Package File
remote_file tarball_file do
  source node.activemq.tarball.url
  not_if { File.exists?("#{node.activemq.source_dir}/bin/activemq") }
end

# Extract and Setup activemq Source directories
bash "extract_activemq_tarball" do
  user  "root"
  cwd   "/tmp"

  code <<-EOS
    tar xzf #{tarball_file}
    mv --force #{tarball_dir} #{node.activemq.source_dir}
    chown -R #{node.activemq.user}:#{node.activemq.group} #{node.activemq.source_dir}
    chmod #{node.activemq.dir_mode} #{node.activemq.source_dir}
  EOS

  not_if  { File.exists?(node.activemq.source_dir) }
  creates "#{node.activemq.install_dir}/bin/activemq" 
  action  :run
end

# Link activemq install_dir to Current source_dir
link node.activemq.install_dir do
  to      node.activemq.source_dir
  owner   node.activemq.user
  group   node.activemq.group
  action  :create
end

arch = node['kernel']['machine'] == 'x86_64' ? 'x86-64' : 'x86-32'

# Link activemq wrapper binary
link File.join(node.activemq.install_dir, 'bin', 'wrapper') do
  to      File.join(node.activemq.install_dir, 'bin', "linux-#{arch}", 'wrapper')
  owner   node.activemq.user
  group   node.activemq.group
  action  :create
end

# Setup Directories for activemq
[ node.activemq.log_dir,
  node.activemq.pid_dir,
  node.activemq.data_dir
].each {|dir|
  directory dir do
    owner     node.activemq.user
    group     node.activemq.group
    mode      node.activemq.dir_mode
    recursive true
    action    :create
  end 
}

template File.join(node.activemq.install_dir, 'conf', 'wrapper.conf') do
  source    "wrapper.conf.erb"
  owner     node.activemq.user
  group     node.activemq.group
  mode      0644
  notifies  :restart, "service[activemq]", :delayed if node.activemq.notify_restart
end

template File.join(node.activemq.install_dir, 'conf', 'activemq.xml') do
  source    "activemq.xml.erb"
  owner     node.activemq.user
  group     node.activemq.group
  mode      0644
  notifies  :restart, "service[activemq]", :delayed if node.activemq.notify_restart
end

template File.join(node.activemq.install_dir, 'conf', 'log4j.properties') do
  source    "log4j.properties.erb"
  owner     node.activemq.user
  group     node.activemq.group
  mode      0644
  notifies  :restart, "service[activemq]", :delayed if node.activemq.notify_restart
end

# activemq Service User limits
user_ulimit node.activemq.user do
  filehandle_limit  node.activemq.limits.nofile
  process_limit     node.activemq.limits.nproc
  memory_limit      node.activemq.limits.memlock
end

ruby_block "require_pam_limits.so" do
  block do
    fe = Chef::Util::FileEdit.new("/etc/pam.d/su")
    fe.search_file_replace_line(/# session    required   pam_limits.so/, "session    required   pam_limits.so")
    fe.write_file
  end
end

template "/etc/init.d/activemq" do
  source  "activemq.init.erb"
  owner   node.activemq.user
  group   node.activemq.group
  mode    0744
end

service "activemq" do
  supports      :start => true, :stop => true, :restart => true, :status => true
  service_name  node.activemq.service_name
  action        [:enable, :start]
end
