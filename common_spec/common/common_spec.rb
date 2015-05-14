require 'spec_helper'

describe command('id') do
  its(:exit_status) { should eq 0 }
end
