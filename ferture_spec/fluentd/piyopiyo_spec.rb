require 'spec_helper'

describe file('/etc') do
  it { should be_directory }
end
