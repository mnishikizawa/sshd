accounts = {
  "test"  => '@on-call',
  "test2" => '@8.8.8.8'
}

accounts.each do |id, from|
  puts  id
  u = data_bag_item('users', id)
  user u['id'] do
    shell u['shell']
    password u['password']
    supports :manage_home => true, :non_unique => false
    action [:create]
  end

  directory "/home/#{id}/.ssh" do
    owner u['id']
    group u['id']
    mode 0700
    action :create
    recursive true
  end

  file "/home/#{id}/.ssh/authorized_keys" do
    owner u['id']
    #group u['id']
    mode 0600
    keys = u['key'].kind_of?(Array) ? u['key'].join("\n") : u['key']
    content keys
  end
end

service 'sshd' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

str = 'AllowUsers'
template "/etc/ssh/sshd_config" do
  owner "root"
  group "root"
  mode 0600
  variables(
    :accounts => accounts,
    :str => str
  )
  only_if "/usr/sbin/sshd -t"
  notifies :reload, 'service[sshd]'
end
