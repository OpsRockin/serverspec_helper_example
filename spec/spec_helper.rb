require 'serverspec'
require "docker"
require 'net/ssh'
require 'yaml'

case ENV['SPEC_BACKEND']
when "DOCKER", 'docker'
  set :backend, :docker
  set :docker_url, ENV['DOCKER_HOST'] || 'unix:///var/run/docker.sock'
  set :docker_image, ENV['DOCKER_IMAGE']
  set :docker_container_create_options, {'Cmd' => ['/bin/sh']}
  Excon.defaults[:ssl_verify_peer] = false
else
  set :backend, :ssh
  set :request_pty, true
  spec_env = ENV['SPEC_ENV']
  if spec_env
    path_candidate = File.expand_path("../../hosts_#{spec_env}", __FILE__)
    puts path_candidate
    if File.exists?(path_candidate)
      hosts_defined = path_candidate
    else
      raise RuntimeError, "\n======\nERROR: No hosts defined for #{spec_env}.\n======"
    end
  else
    hosts_defined = File.expand_path("../../hosts_staging", __FILE__)
  end


  properties = YAML.load_file(hosts_defined)

  host = ENV['TARGET_HOST']
  mainrole = properties.select {|k,v| v[:hosts].include?(host) if v[:hosts] }.keys.first
  host_vars = YAML.load_file(
    File.expand_path("../../host_vars/#{host}.yml", __FILE__)
  ) if File.exists?(File.expand_path("../../host_vars/#{host}.yml", __FILE__))

  spec_property =  properties[mainrole]
  spec_property[:host_vars] =  host_vars ||= {}

  puts spec_property.to_yaml if ENV['DEBUG']

  set_property spec_property
  ENV['SPEC_MAINROLE'] = mainrole

  options = Net::SSH::Config.for(host).merge(properties['shared_settings'][:ssh_opts])

  options.merge!(properties[mainrole][:ssh_opts]) if properties[mainrole][:ssh_opts]
  options[:user] ||= 'root'
  options[:keys] ||= File.expand_path("#{ENV['HOME']}/.ssh/my_staging_key" ,__FILE__)

  set :host,        options[:host_name] || host
  set :ssh_options, options

  # Disable sudo
  # set :disable_sudo, true

  RSpec.configure do |config|
    config.color = true
    config.tty = true
  end

  # Set environment variables
  set :env, :LANG => 'C', :LC_MESSAGES => 'C'
end

