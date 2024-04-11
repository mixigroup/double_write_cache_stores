# DoubleWriteCacheStores

[![test](https://github.com/mixigroup/double_write_cache_stores/actions/workflows/test.yml/badge.svg)](https://github.com/mixigroup/double_write_cache_stores/actions/workflows/test.yml)

pre-warming(double write to cach store and other cache store) cache store wrapper. will switch cache store.

## Support backend cache store

- ActiveSupport::Cache::MemCacheStore
- Dalli::Client

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

### Rails4

`config/application.rb`

```ruby
options = { expires_in: 1.week, compress: true }

read_and_write_cache_store = ActiveSupport::Cache.lookup_store :mem_cache_store, "localhost:11211", options
config.middleware.insert_before "Rack::Runtime", read_and_write_cache_store.middleware

write_only_cache_store = ActiveSupport::Cache.lookup_store :mem_cache_store, "localhost:21211", options

config.cache_store = DoubleWriteCacheStores::Client.new read_and_write_cache_store, write_only_cache_store
```

#### in application

```ruby
Rails.cache.fetch("key") do
  "value"
end
```

## Run tests locally

```
docker compose up -d
bundle install
bundle exec appraisal install
bundle exec appraisal activesupport_7_0 rake

#bundle exec appraisal activesupport_5_2 rake
#bundle exec appraisal activesupport_6_0 rake
#bundle exec appraisal activesupport_6_1 rake
#bundle exec appraisal without_activesupport rake
```

## Contributing

1. Fork it ( http://github.com/mixigroup/double_write_cache_stores/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
