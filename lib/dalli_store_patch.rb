# monky patch
# support cas interface for ActiveSupport::Cache::DalliStore
module DalliStorePatch

  def touch(key, ttl = nil)
    ttl ||= options[:expires_in].to_i
    @data.touch key, ttl
  end

  def read_cas(name, options = {})
    name = namespaced_key(name, options)

    instrument(:get_cas, name) do |_payload|
      with { |c| c.get_cas(name) }
    end
  rescue Dalli::DalliError => e
    logger.error("DalliError: #{e.message}") if logger
    raise if raise_errors?
    false
  end

  def write_cas(name, value, options = {})
    name = namespaced_key(name, options)
    expires_in = options[:expires_in]

    instrument(:set_cas, name, value) do |_payload|
      cas = options.delete(:cas) || 0
      expires_in = options.delete(:expires_in)
      with { |c| c.set_cas(name, value, cas, expires_in, options) }
    end
  rescue Dalli::DalliError => e
    logger.error("DalliError: #{e.message}") if logger
    raise if raise_errors?
    false
  end
end

begin
  require "active_support/cache/dalli_store"

  ActiveSupport::Cache::DalliStore.send(:include, DalliStorePatch)
rescue LoadError # rubocop:disable Lint/HandleExceptions
end
