require 'spec_helper'

describe DoubleWriteCacheStores do
  it 'should have a version number' do
    DoubleWriteCacheStores::VERSION.should_not be_nil
  end
end
