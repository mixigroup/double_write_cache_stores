# monky patch
# support touch interface for ActiveSupport::Cache::MemCacheStore
module MemCacheStorePatch
  def touch(name, ttl = nil)
    key = namespaced_key(name, options)
    ttl ||= options[:expires_in].to_i if options[:expires_in]
    @data.touch(key, ttl)
  rescue Dalli::DalliError => e
    logger.error("DalliError (#{e}): #{e.message}") if logger
    nil
  end

  def read_cas(name, options = nil)
    options ||= {}
    key = namespaced_key(name, options)

    instrument(:get_cas, key) do |_payload|
      @data.get_cas(key)
    end
  rescue Dalli::DalliError => e
    logger.error("DalliError: #{e.message}") if logger
    raise if raise_errors?
    false
  end

  def write_cas(name, value, options = nil)
    options ||= {}
    key = namespaced_key(name, options)
    expires_in = options[:expires_in]

    instrument(:set_cas, key, value) do |_payload|
      cas = options.delete(:cas) || 0
      expires_in = options.delete(:expires_in)
      @data.set_cas(key, value, cas, expires_in, options)
    end
  rescue Dalli::DalliError => e
    logger.error("DalliError: #{e.message}") if logger
    raise if raise_errors?
    false
  end
end

begin
  require "active_support/cache/mem_cache_store"

  ActiveSupport::Cache::MemCacheStore.send(:include, MemCacheStorePatch)
rescue => exception
end
