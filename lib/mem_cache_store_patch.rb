# monky patch
module MemCacheStorePatch
  def dalli
    @data
  end
end

begin
  require "active_support/cache/mem_cache_store"

  ActiveSupport::Cache::MemCacheStore.include MemCacheStorePatch
rescue LoadError # rubocop:disable Lint/SuppressedException
end
