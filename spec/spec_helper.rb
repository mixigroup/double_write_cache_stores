require "pry"

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "double_write_cache_stores"
require "dalli"
require "dalli/cas/client"
