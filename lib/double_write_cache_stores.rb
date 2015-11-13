module DoubleWriteCacheStores
  loaded_active_support = false

  begin
    require "active_support"
    loaded_active_support = true
  rescue LoadError
  end

  loaded_active_support.freeze

  LOADED_ACTIVE_SUPPORT = loaded_active_support

  def self.loaded_active_support?
    LOADED_ACTIVE_SUPPORT
  end
end

require "double_write_cache_stores/version"
require "double_write_cache_stores/client"
require "double_write_cache_stores/base_exception"

require "dalli"
require "dalli_store_patch"

require "mem_cache_store_patch" if DoubleWriteCacheStores.loaded_active_support?
