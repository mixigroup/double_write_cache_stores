class DoubleWriteCacheStores::Client
  def initialize(read_and_write_store_servers, write_only_store_servers = nil)
    @read_and_write_store = read_and_write_store_servers
    if write_only_store_servers
      if read_and_write_store_servers.class != write_only_store_servers.class
        fail "different cache store instance. #{read_and_write_store_servers.class} != #{write_only_store_servers.class}"
      end
      @write_only_store = write_only_store_servers
    end
  end

  def get(key)
    get_or_read_method_call key
  end

  def read(key)
    get_or_read_method_call key
  end

  def delete(key)
    @read_and_write_store.delete key
    @write_only_store.delete key if @write_only_store
  end

  def set(key, value, options = nil)
    write_cache_store __method__, key, value, options
  end

  def write(key, value, options = nil)
    write_cache_store __method__, key, value, options
  end

  def touch(key)
    result = false
    read_and_write_backend = @read_and_write_store.instance_variable_get '@backend'
    if read_and_write_backend && read_and_write_backend.respond_to?(:touch)
      result = read_and_write_backend.touch key
      write_only_store_touch key
    end
    result
  end

  def flush
    if flush_cache_store || flush_cache_store(:clear)
      true
    else
      false
    end
  end

  private

  def write_cache_store(method, key, value, options = nil)
    @read_and_write_store.send method, key, value, options
    @write_only_store.send method, key, value, options if @write_only_store
  end

  def get_or_read_method_call key
    if @read_and_write_store.respond_to? :get
      @read_and_write_store.get key
    elsif @read_and_write_store.respond_to? :read
      @read_and_write_store.read key
    end
  end

  def flush_cache_store(method = :flush)
    if @read_and_write_store.respond_to? method
      if @write_only_store && @write_only_store.respond_to?(method)
        @write_only_store.send method
      end
      @read_and_write_store.send method
    else
      false
    end
  end

  def write_only_store_touch(key)
    if @write_only_store
      if write_only_backend = @write_only_store.instance_variable_get('@backend')
        write_only_backend.touch key if write_only_backend.respond_to?(:touch)
      end
    end
  end
end
