$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "double_write_cache_stores"
require "active_support"
require "dalli"
require "dalli/cas/client"
require "pry"
require "padrino-cache"

PID_DIR   = File.expand_path(File.dirname(__FILE__) + "/../tmp/pids")
PORTS = [11211, 21211]

RSpec.configure do |conf|
  FileUtils.mkdir_p PID_DIR

  PORTS.each do |port|
    pid   = File.expand_path(PID_DIR + "/memcached-spec-#{port}.pid")
    ` memcached -d -p #{port} -P #{pid} `
  end

  conf.after(:suite) do
    PORTS.each do |port|
      pid   = File.expand_path(PID_DIR + "/memcached-spec-#{port}.pid")
      ` cat #{pid} | xargs kill -9 `
    end
  end
end
