# DoubleWriteCacheStores

pre-warning(double write to cach store and other cache store) cache store wrapper. will switch cache store.

## Support

- ActiveSupport::Cache::DalliStore(Dalli)
- Padrino::Cache(v0.12.x)

## Installation

Add this line to your application's Gemfile:

    gem 'double_write_cache_stores'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install double_write_cache_stores

## Usage

### Padrino

`config/apps.rb`
````
read_and_write_cache_store = ActiveSupport::Cache.lookup_store :dalli_store, 'localhost:11211'
write_only_cache_store = ActiveSupport::Cache.lookup_store :dalli_store, 'localhost:21211'

set :cache, DoubleWriteCacheStores::Client.new(read_and_write_cache_store, write_only_cache_store)
````

## Contributing

1. Fork it ( http://github.com/hirocaster/double_write_cache_stores/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
