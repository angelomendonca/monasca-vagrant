# Common setup for all vagrant boxes

## Todo - This apt setup is specific to HP Cloud and should be moved to an optional recipe.

# This move the default apt sources which are the standard ubuntu apt ones aside, so we are forced to deal with what hpcloud has mirrored
bash 'move dist sources.list' do
  action :run
  code 'mv /etc/apt/sources.list /etc/apt/sources.list-dist'
  not_if do ::File.exists?('/etc/apt/sources.list-dist') end
end

apt_repository 'hlinux' do
  uri 'http://hlinux-hrepo.usa.hp.com/hLinux'
  arch 'amd64'
  distribution 'testing'
  components ['main', 'contrib', 'non-free']
  key 'http://hlinux-hrepo.usa.hp.com/hLinuxBrowse/dists/testing/Release.gpg'
end

# Look for a local apt cache, the base repo must be there before the apt cache but it should ideally be before the others
rb = ruby_block "Check for local apt cache" do
  action :nothing
  block do
    if system("wget -T 1 -t 1 http://#{node[:network][:default_gateway]}:#{node[:apt][:cacher_port]}/acng-report.html -O /dev/null > /dev/null 2>&1")
      node.default[:apt][:cacher_ipaddress] = node[:network][:default_gateway]
      node.default[:apt][:cacher_interface] = 'eth0'
      Chef::Log.info('Enabling local apt-cache-ng')
    else
      node.default[:apt][:cacher_ipaddress] = nil
      Chef::Log.info('Disabling local apt-cache-ng')
    end
  end
end

rb.run_action(:create)  # Run during compile time so that apt::cacher-client has the correct variables set

# Add in the cacher-client, it will do something or nothing depending on the value of node[:apt][:cacher_ipaddress]
include_recipe('apt::cacher-client')

apt_repository 'dev' do
  uri 'http://packages.dev.uswest.hpcloud.net/cloud/som/developer'
  arch 'amd64'
  distribution 'precise'
  components ['release']
  key 'http://packages.dev.uswest.hpcloud.net/cloud/som/developer/hpcs.gpg'
end

