require 'rake'
require 'yaml'
require 'rspec/core/rake_task'

spec_env = ENV['SPEC_ENV']
if spec_env
  path_candidate = File.expand_path("../hosts_#{spec_env}", __FILE__)
  if File.exists?(path_candidate)
    hosts_defined = path_candidate
  else
    raise RuntimeError, "\n======\nERROR: No hosts defined for #{spec_env}.\n======"
  end
else
  spec_env = 'staging'
  hosts_defined = File.expand_path("../hosts_staging", __FILE__)
end


properties = YAML.load_file(hosts_defined)

task :spec    => 'spec:all'
task :default => :spec

namespace :spec do
  all_tasks = properties.each_pair.map { |key, values|
    next if key == 'shared_settings'
    values[:hosts].map {|host| 'spec:' + key + ':' + host }
  }.flatten.compact

  desc "all target for #{spec_env}"
  task :all => all_tasks

  properties.each_pair do |master_roll, entries|
    next if master_roll == 'shared_settings'
    role_pattern = entries[:roles].join(',')

    namespace master_roll.to_sym do
      hosts = entries[:hosts]

      desc "all target of #{master_roll} for #{role_pattern}"
      task :all => hosts.map {|h| 'spec:' + master_roll + ':' + h }

      hosts.each do |host|
        desc "Run serverspec tests to #{master_roll}: #{host} for #{role_pattern}"
        RSpec::Core::RakeTask.new(host.to_sym) do |t|
          t.fail_on_error = false
          ENV['TARGET_HOST'] = host
          ENV['SPEC_ENV'] = spec_env
          t.pattern = "{spec,common_spec,ferture_spec}/{#{role_pattern}}/**/*_spec.rb"
        end
      end
    end
  end
end
