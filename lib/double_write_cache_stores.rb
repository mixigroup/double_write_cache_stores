module DoubleWriteCacheStores

  LOADED_ACTIVE_SUPPORT = false

  def self.loaded_active_support?
    LOADED_ACTIVE_SUPPORT
  end
end

begin
  require "active_support"
  DoubleWriteCacheStores::LOADED_ACTIVE_SUPPORT = true
rescue LoadError
end

require "double_write_cache_stores/version"
require "double_write_cache_stores/client"
require "double_write_cache_stores/base_exception"

require "dalli"
require "dalli_store_patch"

if DoubleWriteCacheStores.loaded_active_support?
  require "mem_cache_store_patch"
end
