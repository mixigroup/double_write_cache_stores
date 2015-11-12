require "spec_helper"

def get_or_read(store, key)
  if store.respond_to? :get
    store.get key
  else
    store.read key
  end
end

describe DoubleWriteCacheStores::Client do
  describe '#initialize' do
    let(:options) { { namespace: "app_v1", compress: true } }
    it "different cache store instance" do
      expect { DoubleWriteCacheStores::Client.new Dalli::Client.new("localhost:11211", options), "bad instance object" }.to raise_error RuntimeError
    end
  end

  shared_examples "Equal values" do |cache_store, key, value|
    let(:rw_store) { cache_store.read_and_write_store }
    let(:rw_value) { get_or_read(rw_store, key) }

    describe "Equal values" do

      it "Read and Write cache store" do
        expect(rw_value).to eq value
      end

      if w_store = cache_store.write_only_store
        it "Write cache store" do
          w_value = get_or_read(w_store, key)
          expect(w_value).to eq value
        end

        it "RW == W cache store's values" do
          w_value = get_or_read(w_store, key)
          expect(rw_value).to eq w_value
        end
      end
    end
  end

  shared_examples "cache store example" do |cache_store|
    describe '#read_multi' do
      before do
        cache_store.write "key-a", "example-value-a", expires_in: 86400
        cache_store.write "key-b", "example-value-b", expires_in: 86400
      end

      after { cache_store.flush }

      it "get multi-keys values from multi store" do
        results = cache_store.read_multi("key-a", "key-b", "key-c")
        expect(results["key-a"]).to eq "example-value-a"
        expect(results["key-b"]).to eq "example-value-b"
        expect(results["key-c"]).to eq nil
      end

      it 'returns values equal #get_multi' do
        expect(cache_store.read_multi("key-a", "key-b")).to eq cache_store.get_multi("key-a", "key-b")
      end
    end

    describe '#fetch' do
      before do
        cache_store.write "key-a", "example-value-a", expires_in: 1
      end

      after { cache_store.flush }

      it "returns value" do
        expect(cache_store.fetch("key-a"){ "faild-value" }).to eq "example-value-a"
        expect{ cache_store.fetch("error") }.to raise_error LocalJumpError
      end

      it "get value and set value, block in args" do
        cache_store.fetch("key-b") do
          "block-value-b"
        end

        expect(cache_store.fetch("key-b") { "faild-value" }).to eq "block-value-b"
        expect(cache_store.get("key-b")).to eq "block-value-b"

        result = cache_store.fetch("key-b") do
          "not-overwrite-value"
        end
        expect(cache_store.fetch("key-b") { "faild-value" }).to eq "block-value-b"
        expect(cache_store.get("key-b")).to eq "block-value-b"

        cache_store.fetch("key-c", expires_in: 1) do
          "c-value"
        end
        expect(cache_store.fetch("key-c") { "faild-value" }).to eq "c-value"
        sleep 2
        expect(cache_store.get("key-c")).to be_nil
      end

      it "Support force read option, convertible Rails.cache" do
        cached_value = cache_store.fetch("key-c") do
                         "block-value-c"
                       end
        expect(cache_store.fetch("key-c") { "faild-value" }).to eq "block-value-c"

        new_value = cache_store.fetch("key-c", force: true) do
                         "block-value-c-force"
                    end

        expect(new_value).to eq "block-value-c-force"
        expect(cache_store.fetch("key-c") { "faild-value" }).to eq "block-value-c-force"
      end
    end

    describe '#delete' do
      before do
        cache_store.write "will-delete-key", "example-will-delete-value", expires_in: 86400
      end

      it "delete key-value" do
        expect(cache_store.delete "will-delete-key").to be true
        expect(cache_store.read "will-delete-key").to be_nil

        value = if cache_store.read_and_write_store.respond_to? :read
                  cache_store.read_and_write_store.read "will-delete-key"
                else
                  cache_store.read_and_write_store.get "will-delete-key"
                end
        expect(value).to be_nil

        if cache_store.write_only_store
          value = if cache_store.write_only_store.respond_to? :read
                    cache_store.write_only_store.read "will-delete-key"
                  else
                    cache_store.write_only_store.get "will-delete-key"
                  end
          expect(value).to be_nil
        end
      end
    end

    describe '#touch' do
      let(:expire_ttl) { 1 }

      before do
        cache_store.set "touch-key", "touch-value", expires_in: expire_ttl
      end

      it "expired value, not touched" do
        sleep expire_ttl
        expect(cache_store.read "touch-key").to eq nil
      end

      it "expired value, touched expired" do
        expect(cache_store.touch "touch-key", expire_ttl).to be true
        sleep expire_ttl
        expect(cache_store.read "touch-key").to eq nil
      end

      it "returns value, before touched key" do
        expect(cache_store.touch "touch-key").to be true
        sleep expire_ttl
        expect(cache_store.read "touch-key").to eq "touch-value"
      end
    end

    describe '#write' do
      before do
        cache_store.write "key", "example-write-value", expires_in: 86400
      end

      it "returns writed value" do
        expect(cache_store.read "key").to eq "example-write-value"
      end

      it_behaves_like "Equal values", cache_store, "key", "example-write-value"

      it "writed to read_and_write_store" do
        value = if cache_store.read_and_write_store.respond_to? :get
                  cache_store.read_and_write_store.get "key"
                else
                  cache_store.read_and_write_store.read "key"
                end
        expect(value).to eq "example-write-value"
      end

      if cache_store.write_only_store
        it "writed to write_only_store" do
          value = if cache_store.write_only_store.respond_to? :get
                    cache_store.write_only_store.get "key"
                  else
                    cache_store.write_only_store.read "key"
                  end
          expect(value).to eq "example-write-value"
        end
      end
    end

    describe '#read' do
      before do
        cache_store.write "key", "example-read-value", expires_in: 86400
      end

      it "returns writed value" do
        expect(cache_store.read "key").to eq "example-read-value"
      end

      it "returns nil, not writed value" do
        expect(cache_store.read "not-set-key").to eq nil
      end
    end

    describe '#flush' do
      before do
        cache_store.write "will-flush-key", "will-flush-value", expires_in: 86400
        expect(cache_store.read "will-flush-key").to eq "will-flush-value"
        expect(cache_store.flush).to eq true
      end

      it "retuns nil" do
        expect(cache_store.read "will-flush-key").to eq nil
      end

      it_behaves_like "Equal values", cache_store, "will-flush-key", nil
    end

    shared_examples "read cache after increment or decrement example" do
      before { cache_store.set(key, 10, raw: true) }
      it { expect((cache_store.read key).to_i).to eq expected_value }
    end

    describe '#increment' do
      let(:key) { "key-increment" }
      after     { cache_store.flush }

      it_behaves_like "read cache after increment or decrement example" do
        let!(:expected_value) { cache_store.increment key }
      end

      context "when options[:initial] does not exist" do
        context "when value exists" do
          before { cache_store.set(key, 0, raw: true) }
          context "when amount does not exist" do
            it { expect(cache_store.increment key).to eq 1 }

            context "incremented value in cache stores" do
              before { cache_store.increment key }
              it_behaves_like("Equal values", cache_store, "key-increment", "1")
            end

          end
          context "when amount exists" do
            it { expect(cache_store.increment key, 2).to eq 2 }
          end
        end
        context "when value does not exist" do
          if DoubleWriteCacheStores.loaded_active_support? && cache_store.read_and_write_store.is_a?(ActiveSupport::Cache::MemCacheStore)
            skip "Not support"
          else
            context "when amount does not exist" do
              it { expect(cache_store.increment key).to eq 1 }
            end
            context "when amount exists" do
              it { expect(cache_store.increment key, 2).to eq 2 }
            end
          end
        end
      end

      context "when options[:initial] exists" do
        if DoubleWriteCacheStores.loaded_active_support? && cache_store.read_and_write_store.is_a?(ActiveSupport::Cache::MemCacheStore)
          skip "Not support"
        else
          let(:opt) { { initial: 12_345_678 } }
          context "when value exists" do
            before { cache_store.set(key, 0, raw: true) }
            it { expect(cache_store.increment key, 1, opt).to eq 1 }
          end
          context "when value does not exist" do
            it { expect(cache_store.increment key, 1, opt).to eq opt[:initial] }
          end
        end
      end
    end

    describe '#decrement' do
      let(:key) { "key-decrement" }
      after     { cache_store.flush }

      it_behaves_like "read cache after increment or decrement example" do
        let!(:expected_value) { cache_store.decrement key }
      end

      context "when options[:initial] does not exist" do
        context "when value exists" do
          before { cache_store.set(key, 101, raw: true) }
          context "when amount does not exist" do
            it { expect(cache_store.decrement key).to eq 100 }

            context "decremented value in cache stores" do
              before { cache_store.decrement key }
              it_behaves_like("Equal values", cache_store, "key-decrement", "100")
            end

          end
          context "when amount exists" do
            it { expect(cache_store.decrement key, 2).to eq 99 }
          end
        end
        context "when value does not exist" do
          if DoubleWriteCacheStores.loaded_active_support? && cache_store.read_and_write_store.is_a?(ActiveSupport::Cache::MemCacheStore)
            skip "Not support"
          else
            context "when amount does not exist" do
              it { expect(cache_store.decrement key).to eq 0 }
            end
            context "when amount exists" do
              it { expect(cache_store.decrement key, 2).to eq 0 }
            end
          end
        end
      end

      context "when options[:initial] exists" do
        if DoubleWriteCacheStores.loaded_active_support? && cache_store.read_and_write_store.is_a?(ActiveSupport::Cache::MemCacheStore)
          skip "Not support"
        else
          let(:opt) { { initial: 12_345_678 } }
          context "when value exists" do
            before { cache_store.set(key, 101, raw: true) }
            it { expect(cache_store.decrement key, 1, opt).to eq 100 }
          end
          context "when value does not exist" do
            it { expect(cache_store.decrement key, 1, opt).to eq opt[:initial] }
          end
        end
      end
    end

    describe '#[]=(key,value) and get #[](key)' do
      it "set value and get value" do
        cache_store["key"] = "example-value"
        expect(cache_store["key"]).to eq "example-value"
      end

      context "seted value in cache stores" do
        before { cache_store["key"] = "value" }
        it_behaves_like("Equal values", cache_store, "key", "value")
      end
    end

    describe "cas" do
      describe '#get_cas' do
        before do
          cache_store.set_cas "get-cas-key", "get-cas-value"
        end

        it "example" do
          expect(cache_store.get_cas("get-cas-key")[0]).to eq "get-cas-value"
          expect(cache_store.get_cas("get-cas-key")[1]).to be_kind_of(Integer)
        end

        it_behaves_like("Equal values", cache_store, "get-cas-key", "get-cas-value")
      end

      describe '#set_cas' do
        let :cas_unique do
          cache_store.set_cas("set-cas-key", "set-cas-value")
          cache_store.get_cas("set-cas-key")[1]
        end

        it "example" do
          expect(cache_store.set_cas("set-cas-key", "set-cas-value", cas_unique)).to be_kind_of(Integer)
        end

        it "returns false, not set cache because different cas_unique" do
          expect(cache_store.set_cas("set-cas-key", "set-cas-value", cas_unique - 1)).to eq false
        end
      end
    end
  end

  describe "shard example" do
    if DoubleWriteCacheStores.loaded_active_support?
      context "ActiveSupport MemCacheStore" do

        options = { raw: true, expires_in: 3600 }

        read_and_write_store = ActiveSupport::Cache.lookup_store :mem_cache_store, "localhost:11211", options
        write_only_store = ActiveSupport::Cache.lookup_store :mem_cache_store, "localhost:21211", options

        context "double cache store" do
          copy_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store, write_only_store)
          it_behaves_like "cache store example", copy_cache_store
        end

        context "one cache store object" do
          one_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store, nil)
          it_behaves_like "cache store example", one_cache_store
        end
      end

      context "ActiveSupport :dalli_store in Dalli" do
        read_and_write_store = ActiveSupport::Cache.lookup_store :dalli_store, "localhost:11211"
        write_only_store = ActiveSupport::Cache.lookup_store :dalli_store, "localhost:21211"

        context "double cache store" do
          copy_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store, write_only_store)
          it_behaves_like "cache store example", copy_cache_store
        end

        context "one cache store object" do
          one_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store, nil)
          it_behaves_like "cache store example", one_cache_store
        end
      end
    else
      skip "Not load ActiveSupport"
    end

    context "Dalli::Client" do
      options = { namespace: "app_v1", compress: true }
      read_and_write_store = Dalli::Client.new("localhost:11211", options)
      write_only_store = Dalli::Client.new("localhost:21211", options)

      context "double cache store" do
        copy_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store, write_only_store)
        it_behaves_like "cache store example", copy_cache_store
      end

      context "one cache store" do
        one_cache_store = DoubleWriteCacheStores::Client.new(read_and_write_store)
        it_behaves_like "cache store example", one_cache_store
      end
    end
  end
end
