require 'spec_helper'

describe DoubleWriteCacheStores::Client do
  let :read_and_write_store do
    ActiveSupport::Cache.lookup_store :dalli_store, 'localhost:11211'
  end

  let :write_only_store do
    ActiveSupport::Cache.lookup_store :dalli_store, 'localhost:21211'
  end

  describe '#initialize' do
    it 'different cache store instance' do
      expect{ subject.new read_and_write_store, 'bad instance object' }.to raise_error
    end
  end

  let :copy_cache_store do
    DoubleWriteCacheStores::Client.new read_and_write_store, write_only_store
  end

  describe '#write' do
    before do
      copy_cache_store.write 'key', 'example-value', :expires_in => 1.day
    end
    it 'set value to multi store' do
      expect(read_and_write_store.read 'key').to eq 'example-value'
      expect(write_only_store.read 'key').to eq 'example-value'
    end
  end

  describe 'set #[]=(key, value) and get #[](key)' do
    it 'set value and get value' do
      copy_cache_store['key'] = 'example-value'
      expect(copy_cache_store['key']).to eq 'example-value'
    end
  end

  describe '#delete' do
    before do
      copy_cache_store.write 'will-delete-key', 'example-will-delete-value', :expires_in => 1.day
    end
    it 'delete key-value' do
      expect(read_and_write_store.read 'will-delete-key').to eq 'example-will-delete-value'
      expect(write_only_store.read 'will-delete-key').to eq 'example-will-delete-value'

      copy_cache_store.delete 'will-delete-key'

      expect(read_and_write_store.read 'will-delete-key').to be_nil
      expect(write_only_store.read 'will-delete-key').to be_nil
    end
  end

  describe '#touch' do
    let :options do
      { :namespace => "app_v1", :compress => true }
    end
    let :support_touch_read_and_write_store do
      Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('localhost:11211', options))
    end
    let :support_touch_write_only_store do
      Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('localhost:21211', options))
    end
    let :support_touch_copy_cache_store do
      DoubleWriteCacheStores::Client.new support_touch_read_and_write_store, support_touch_write_only_store
    end
    before do
      support_touch_copy_cache_store.set 'touch-key', 'touch-value', :expires_in => 1.day
    end

    context 'Dalli::Client' do
      it 'example' do
        expect(support_touch_copy_cache_store.touch 'touch-key').to be true
        expect(support_touch_copy_cache_store.touch 'non-set-key').to be nil
      end
    end

    context 'ActiveSupport::Cache::DalliStore' do
      let :double_write_dalli_store do
        DoubleWriteCacheStores::Client.new ActiveSupport::Cache::DalliStore.new('localhost:11211', options), ActiveSupport::Cache::DalliStore.new('localhost:21211', options)
      end

      before do
        double_write_dalli_store.set 'touch-key', 'touch-valule', :expires_in => 1.day
      end

      it 'example' do
        expect(double_write_dalli_store.touch 'touch-key').to be true
        expect(double_write_dalli_store.touch 'non-set-key').to be nil
      end
    end
  end

  describe '#read' do
    context 'when standard case' do
      before do
        copy_cache_store.write 'key', 'example-read-value', :expires_in => 1.day
      end
      it 'get read key value from multi store' do
        expect(copy_cache_store.read 'key').to eq 'example-read-value'
      end
      it 'not get no set key-value' do
        expect(copy_cache_store.read 'not-set-key').to be_nil
      end
    end
    context 'when not set copy cache store' do
      let :not_copy_cache_store do
        DoubleWriteCacheStores::Client.new read_and_write_store
      end
      before do
        not_copy_cache_store.write 'no-copy-key', 'example-read-value', :expires_in => 1.day
      end
      it 'not sync cache store' do
        expect(read_and_write_store.read 'no-copy-key').to eq 'example-read-value'
        expect(write_only_store.read 'no-copy-key').to be_nil
      end
    end
  end

  describe '#flush' do
    context 'when not support flush method in cache store' do
      before do
        copy_cache_store.write 'will-flush-key', 'will-flush-value', :expires_in => 1.day
      end
      it 'example' do
        expect(copy_cache_store.flush).to eq true
        expect(copy_cache_store.read 'will-flush-key').to be_nil
      end
    end
    context 'when support flush method in backend cache store' do
      let :options do
        { :namespace => "app_v1", :compress => true }
      end
      let :support_flash_read_and_write_store do
        Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('localhost:11211', options))
      end
      let :support_flash_write_only_store do
        Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('localhost:21211', options))
      end
      let :support_flash_copy_cache_store do
        DoubleWriteCacheStores::Client.new support_flash_read_and_write_store, support_flash_write_only_store
      end
      before do
        support_flash_copy_cache_store.set 'will-flush-key',  'will-flush-value', :expires_in => 1.day
      end
      it 'example' do
        expect(support_flash_copy_cache_store.get 'will-flush-key').to eq 'will-flush-value'
        expect(support_flash_copy_cache_store.flush).to be true
        expect(support_flash_copy_cache_store.get 'will-flush-key').to be_nil
      end
    end
  end

  describe "#get_cas" do
    context "when support get_cas method in backend cache store" do
      let :support_get_cas_cache_store do
        read_and_write = ::Dalli::Client.new(['localhost:11211'])
        write_only = ::Dalli::Client.new(['localhost:21211'])
        DoubleWriteCacheStores::Client.new read_and_write, write_only
      end

      before do
        support_get_cas_cache_store.set 'cas-dalli-key', 'cas-dalli-value'
      end

      it 'example' do
        expect(support_get_cas_cache_store.get_cas('cas-dalli-key')[0]).to eq 'cas-dalli-value'
        expect(support_get_cas_cache_store.get_cas('cas-dalli-key')[1]).to be_kind_of(Integer)
      end
    end

    context "when doesn't support get_cas method in backend cache store" do
      let :not_support_get_cas_cache_store do
        DoubleWriteCacheStores::Client.new ActiveSupport::Cache::DalliStore.new('localhost:11211'), ActiveSupport::Cache::DalliStore.new('localhost:21211')
      end

      it 'should raise NoMethodError' do
        expect{ not_support_get_cas_cache_store.get_cas 'cas-key' }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#set_cas" do
    context "when support set_cas method in backend cache store" do
      let :support_set_cas_cache_store do
        read_and_write = ::Dalli::Client.new(['localhost:11211'])
        write_only = ::Dalli::Client.new(['localhost:21211'])
        DoubleWriteCacheStores::Client.new read_and_write, write_only
      end
      let :cas_unique do
        support_set_cas_cache_store.set('cas-dalli-key', 'cas-value')
        support_set_cas_cache_store.get_cas('cas-dalli-key')[1]
      end

      it 'example' do
        expect(support_set_cas_cache_store.set_cas('cas-dalli-key', 'cas-dalli-value', cas_unique)).to be_kind_of(Integer)
      end
    end

    context "when doesn't support set_cas method in backend cache store" do
      let :not_support_set_cas_cache_store do
        DoubleWriteCacheStores::Client.new ActiveSupport::Cache::DalliStore.new('localhost:11211'), ActiveSupport::Cache::DalliStore.new('localhost:21211')
      end

      it 'should raise NoMethodError' do
        expect{ not_support_set_cas_cache_store.set_cas('cas-key', 'cas-value', 1) }.to raise_error(NoMethodError)
      end
    end
  end
end
